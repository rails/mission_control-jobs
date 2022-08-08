class ActiveJob::JobsRelation
  include Enumerable

  PROPERTIES = %i[ queue_name status offset_value limit_value job_class_names ]
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
    clone_with job_class_names: job_class, queue_name: queue
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
    queue_adapter.jobs_count(self)
  end

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

    def job_class_names=(job_class_name_or_names)
      @job_class_names = Array(job_class_name_or_names) if job_class_name_or_names
    end
end
