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

  # Returns a +ActiveJob::JobsRelation+ with the configured filtering options
  #
  # === Options
  #
  # * <tt>:job_class</tt> - A string with the class name or class names of
  #   jobs to filter.
  def where(job_class: nil, queue: nil)
    clone_with job_class_name: job_class.to_s, queue_name: queue.to_s
  end

  STATUSES.each do |status|
    define_method status do
      clone_with status: status
    end

    define_method "#{status}?" do
      self.status == status
    end
  end

  def offset(offset)
    clone_with offset_value: offset
  end

  def limit(limit)
    clone_with limit_value: limit
  end

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
      filtered_jobs = filter_if_needed(jobs)
      Array(filtered_jobs).each { |job| yield job }
      current_offset += limit
    end until (jobs.blank? && jobs.length == filtered_jobs.length)
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

    def filter_if_needed(jobs)
      if filtering_needed?
        filter(jobs)
      else
        jobs
      end
    end

    # If adapter does not support filtering by class name, it will perform
    # the filtering in memory.
    def filtering_needed?
      job_class_name.present? && !queue_adapter.support_class_name_filtering?
    end

    def filter(jobs)
      jobs.filter { |job| satisfy_filter?(job) }
    end

    def satisfy_filter?(job)
      job.class_name == job_class_name
    end
end
