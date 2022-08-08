class ActiveJob::JobsRelation
  PROPERTIES = %i[ queue_name status from_index to_index job_class_names ]
  STATUSES = %i[ pending failed ]

  attr_reader *PROPERTIES

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter)
    @queue_adapter = queue_adapter

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

  def from(from)
    clone_with from_index: from
  end

  def to(to)
    clone_with to_index: to
  end

  def count
    queue_adapter.count_jobs(self)
  end

  private
    attr_reader :queue_adapter
    attr_writer *PROPERTIES

    def set_defaults
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
