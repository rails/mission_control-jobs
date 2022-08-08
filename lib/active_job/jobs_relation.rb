class ActiveJob::JobsRelation
  include Enumerable

  PROPERTIES = %i[ failed queue_name from to job_class ]

  attr_reader *PROPERTIES

  def initialize(queue_name: nil, failed: false, from: nil, to: nil)
    @queue_name = queue_name
    @failed = failed
    @from = from
    @to = to
  end

  def where(job_class: nil, queue: nil)
    clone_with only_job_classes: job_class, queue_name: queue
  end

  def failed
    clone_with failed: true
  end

  def from(from)
    clone_with from: from
  end

  def to(to)
    clone_with to: to
  end

  def each(&block) end

  private
    attr_writer *PROPERTIES

    def clone_with(**properties)
      dup.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end
end
