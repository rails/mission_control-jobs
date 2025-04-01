# A proxy for managing jobs without having to load the corresponding
# job class.
#
# This is useful for managing jobs without having the job classes
# present in the code base.
class ActiveJob::JobProxy < ActiveJob::Base
  class UnsupportedError < StandardError; end

  attr_reader :job_class_name

  def initialize(job_data)
    super
    @job_class_name = job_data["job_class"]
    deserialize(job_data)
  end

  def serialize
    super.tap do |json|
      json["job_class"] = @job_class_name
    end
  end

  def error
    @last_execution_error.to_s
  end

  def perform_now
    raise UnsupportedError, "A JobProxy doesn't support immediate execution, only enqueuing."
  end

  ActiveJob::JobsRelation::STATUSES.each do |status|
    define_method "#{status}?" do
      self.status == status
    end
  end
end
