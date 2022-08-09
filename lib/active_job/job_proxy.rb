# A proxy for managing jobs without having to load the
# corresponding job class.
#
# This is useful for managing jobs without having the job
# classes present in the code base.
class ActiveJob::JobProxy < ActiveJob::Base
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
end
