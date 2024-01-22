# A relation of jobs that can be filtered and acted on.
#
# Relations of jobs are normally fetched via +ActiveJob::Base.jobs+
# or through a given queue (+ActiveJob::Queue#jobs+).
#
# This class offers a fluid interface to query a subset of jobs. For
# example:
#
#   queue = ActiveJob::Base.queues[:default]
#   queue.jobs.limit(10).where(job_class: "DummyJob").last
#
# Relations are enumerable, so you can use +Enumerable+ methods on them.
# Notice however that using these methods will imply loading all the relation
# in memory, which could introduce performance concerns.
#
# Internally, +ActiveJob+ will always use paginated queries to the underlying
# queue adapter. The page size can be controlled via +config.active_job.default_page_size+
# (1000 by default).
#
# There are additional performance concerns depending on the configured
# adapter. Please check +ActiveJob::Relation#where+, +ActiveJob::Relation#count+.
class ActiveJob::JobsRelation
  include Enumerable

  STATUSES = %i[ pending failed in_progress blocked scheduled finished ]

  PROPERTIES = %i[ queue_name status offset_value limit_value job_class_name ]
  attr_reader *PROPERTIES, :default_page_size

  delegate :last, :[], :reverse, to: :to_a
  delegate :logger, to: MissionControl::Jobs

  ALL_JOBS_LIMIT = 100_000_000 # When no limit value it defaults to "all jobs"

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter, default_page_size: ActiveJob::Base.default_page_size)
    @queue_adapter = queue_adapter
    @default_page_size = default_page_size

    set_defaults
  end

  # Returns a +ActiveJob::JobsRelation+ with the configured filtering options.
  #
  # === Options
  #
  # * <tt>:job_class</tt> - To only include the jobs of a given class.
  #   Depending on the configured queue adapter, this will perform the
  #   filtering in memory, which could introduce performance concerns
  #   for large sets of jobs.
  # * <tt>:queue</tt> - To only include the jobs in the provided queue.
  def where(job_class: nil, queue: nil)
    # Remove nil arguments to avoid overriding parameters when concatenating +where+ clauses
    arguments = { job_class_name: job_class, queue_name: queue }.compact.collect { |key, value| [ key, value.to_s ] }.to_h
    clone_with **arguments
  end

  # This allows to unset a previous +job_class+ set in the relation.
  def with_all_job_classes
    if job_class_name.present?
      clone_with job_class_name: nil
    else
      self
    end
  end

  STATUSES.each do |status|
    define_method status do
      clone_with status: status
    end

    define_method "#{status}?" do
      self.status == status
    end
  end

  # Sets an offset for the jobs-fetching query. The first position is 0.
  def offset(offset)
    clone_with offset_value: offset
  end

  # Sets the max number of jobs to fetch in the query.
  def limit(limit)
    clone_with limit_value: limit
  end

  # Returns the number of jobs in the relation.
  #
  # When filtering jobs by class name, if the adapter doesn't support
  # it directly, this will imply loading all the jobs in memory.
  def count
    if loaded? || filtering_by_class_name_needed?
      to_a.length
    else
      query_count
    end
  end

  alias length count
  alias size count

  def empty?
    count == 0
  end

  def to_s
    properties_with_values = PROPERTIES.collect do |name|
      value = public_send(name)
      "#{name}: #{value}" unless value.nil?
    end.compact.join(", ")
    "<Jobs with [#{properties_with_values}]> (loaded: #{loaded?})"
  end

  alias inspect to_s

  def each(&block)
    loaded_jobs&.each(&block) || load_jobs(&block)
  end

  # Retry all the jobs in the queue.
  #
  # This operation is only valid for sets of failed jobs. It will
  # raise an error +ActiveJob::Errors::InvalidOperation+ otherwise.
  def retry_all
    ensure_failed_status
    queue_adapter.retry_all_jobs(self)
    nil
  end

  # Retry the provided job.
  #
  # This operation is only valid for sets of failed jobs. It will
  # raise an error +ActiveJob::Errors::InvalidOperation+ otherwise.
  def retry_job(job)
    ensure_failed_status
    queue_adapter.retry_job(job, self)
  end

  # Discard all the jobs in the relation.
  def discard_all
    queue_adapter.discard_all_jobs(self)
    nil
  end

  # Discard the provided job.
  def discard_job(job)
    queue_adapter.discard_job(job, self)
  end

  # Find a job by id.
  #
  # Returns nil when not found.
  def find_by_id(job_id)
    queue_adapter.find_job(job_id, self)
  end

  # Find a job by id.
  #
  # Raises +ActiveJob::Errors::JobNotFoundError+ when not found.
  def find_by_id!(job_id)
    queue_adapter.find_job(job_id, self) or raise ActiveJob::Errors::JobNotFoundError.new(job_id, self)
  end

  # Returns an array of jobs classes in the first +from_first+ jobs.
  def job_classes(from_first: 500)
    first(from_first).collect(&:class_name).uniq
  end

  def reload
    @count = nil
    @loaded_jobs = nil

    self
  end

  def in_batches(of: default_page_size, order: :asc, &block)
    validate_looping_in_batches_is_possible

    case order
    when :asc
      in_ascending_batches(of: of, &block)
    when :desc
      in_descending_batches(of: of, &block)
    else
      raise "Unsupported order: #{order}. Valid values: :asc, :desc."
    end
  end

  def paginated?
    offset_value > 0 || limit_value_provided?
  end

  def limit_value_provided?
    limit_value.present? && limit_value != ActiveJob::JobsRelation::ALL_JOBS_LIMIT
  end

  private
    attr_reader :queue_adapter, :loaded_jobs
    attr_writer *PROPERTIES

    def set_defaults
      self.offset_value = 0
      self.limit_value = ALL_JOBS_LIMIT
    end

    def clone_with(**properties)
      dup.reload.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end

    def query_count
      @count ||= queue_adapter.jobs_count(self)
    end

    def load_jobs
      @loaded_jobs = []
      perform_each do |job|
        @loaded_jobs << job
        yield job
      end
    end

    def perform_each
      current_offset = offset_value
      pending_count = limit_value || Float::INFINITY

      begin
        limit = [ pending_count, default_page_size ].min
        page = offset(current_offset).limit(limit)
        jobs = queue_adapter.fetch_jobs(page)
        finished = jobs.empty?
        jobs = filter_by_class_name(jobs) if filtering_by_class_name_needed?
        Array(jobs).each { |job| yield job }
        current_offset += limit
        pending_count -= jobs.length
      end until finished || pending_count.zero?
    end

    def loaded?
      !@loaded_jobs.nil?
    end

    def filter_by_class_name(jobs)
      jobs.filter { |job| satisfy_class_name_filter?(job) }
    end

    # If adapter does not support filtering by class name, it will perform
    # the filtering in memory.
    def filtering_by_class_name_needed?
      job_class_name.present? && !queue_adapter.support_class_name_filtering?
    end

    def satisfy_class_name_filter?(job)
      job.class_name == job_class_name
    end

    def ensure_failed_status
      raise ActiveJob::Errors::InvalidOperation, "This operation can only be performed on failed jobs, but these jobs are #{status}" unless failed?
    end

    def validate_looping_in_batches_is_possible
      raise ActiveJob::Errors::InvalidOperation, "Looping in batches is not compatible with providing offset or limit" if paginated?
    end

    def in_ascending_batches(of:)
      current_offset = 0
      max = count
      begin
        page = offset(current_offset).limit(of)
        current_offset += of
        logger.info page
        yield page
        wait_batch_delay
      end until current_offset >= max
    end

    def in_descending_batches(of:)
      current_offset = count - of

      begin
        limit = current_offset < 0 ? of + current_offset : of
        page = offset([ current_offset, 0 ].max).limit(limit)
        current_offset -= of
        logger.info page
        yield page
        wait_batch_delay
      end until current_offset + of <= 0
    end

    def wait_batch_delay
      sleep MissionControl::Jobs.delay_between_bulk_operation_batches if MissionControl::Jobs.delay_between_bulk_operation_batches.to_i > 0
    end
end
