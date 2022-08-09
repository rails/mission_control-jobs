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

  PROPERTIES = %i[ queue_name status offset_value limit_value job_class_name ]
  STATUSES = %i[ pending failed ]

  attr_reader *PROPERTIES

  delegate :last, :[], to: :to_a

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
    # Remove nil arguments to avoid overriding parameters when concatenating where clauses
    arguments = { job_class_name: job_class, queue_name: queue }.compact.collect { |key, value| [ key, value.to_s ] }.to_h
    clone_with **arguments
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
    if filtering_needed?
      to_a.length
    else
      queue_adapter.jobs_count(self)
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
    "<Jobs with [#{properties_with_values}]>"
  end

  alias inspect to_s

  def each
    current_offset = offset_value
    begin
      limit = [ limit_value || default_page_size, default_page_size ].min
      page = offset(current_offset).limit(limit)
      jobs = queue_adapter.fetch_jobs(page)
      jobs = filter(jobs) if filtering_needed?
      Array(jobs).each { |job| yield job }
      current_offset += limit
    end until jobs.blank?
  end

  private
    attr_reader :queue_adapter, :default_page_size
    attr_writer *PROPERTIES

    def set_defaults
      self.offset_value = 0
      self.status = :pending
    end

    def clone_with(**properties)
      dup.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end

    def filter(jobs)
      jobs.filter { |job| satisfy_filter?(job) }
    end

    # If adapter does not support filtering by class name, it will perform
    # the filtering in memory.
    def filtering_needed?
      job_class_name.present? && !queue_adapter.support_class_name_filtering?
    end

    def satisfy_filter?(job)
      job.class_name == job_class_name
    end
end
