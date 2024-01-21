# A proxy for managing jobs without having to load the corresponding
# job class.
#
# This is useful for managing jobs without having the job classes
# present in the code base.
class ActiveJob::JobProxy < ActiveJob::Base
  class UnsupportedError < StandardError; end

  attr_reader :class_name
  attr_writer :status

  def initialize(job_data)
    super
    @class_name = job_data["job_class"]
    deserialize(job_data)
  end

  def serialize
    super.tap do |json|
      json["job_class"] = @class_name
    end
  end

  def status
    return @status if @status.present?

    failed? ? :failed : :pending
  end

  def perform_now
    raise UnsupportedError, "A JobProxy doesn't support immediate execution, only enqueuing."
  end

  def to_partial_path
    "jobs/job"
  end
end
