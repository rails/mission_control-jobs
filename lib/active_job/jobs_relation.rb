class ActiveJob::JobsRelation
  PROPERTIES = %i[ only_failed queue_name from_index to_index job_class_names ]

  attr_reader *PROPERTIES

  # Returns a +ActiveJob::JobsRelation+ with the configured filtering options
  #
  # === Options
  #
  # * <tt>:job_class</tt> - A string with the class names of the jobs to filter.
  #   It also supports passing an array to include multiple job classes.
  def where(job_class: nil, queue: nil)
    clone_with job_class_names: job_class, queue_name: queue
  end

  def failed
    clone_with only_failed: true
  end

  alias only_failed? only_failed

  def from(from)
    clone_with from_index: from
  end

  def to(to)
    clone_with to_index: to
  end

  private
    attr_writer *PROPERTIES

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
