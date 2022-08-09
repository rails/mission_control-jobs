# A proxy for managing jobs without having to load the corresponding
# job class.
#
# This is useful for managing jobs without having the job classes
# present in the code base.
#
class ActiveJob::JobProxy < ActiveJob::Base
  class UnsupportedError < StandardError; end

  attr_reader :class_name

  def initialize(job_data)
    @class_name = job_data["job_class"]
    deserialize(job_data)
  end

  def serialize
    super.tap do |json|
      json["job_class"] = @class_name
    end
  end

  def perform_now
    raise UnsupportedError, "A JobProxy doesn't support immediate execution, only enqueuing."
  end
end
