# TODO: These should be moved to +ActiveJob::Core+ and related concerns
# when upstreamed.
module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    attr_accessor :raw_data, :position
    attr_reader :serialized_arguments
    thread_cattr_accessor :current_queue_adapter
  end

  class_methods do
    def queue_adapter
      ActiveJob::Base.current_queue_adapter || super
    end
  end

  def retry
    ActiveJob.jobs.failed.retry_job(self)
  end

  def discard
    jobs_relation.discard_job(self)
  end

  private
    def jobs_relation
      if failed?
        ActiveJob.jobs.failed
      else
        ActiveJob.jobs.where(queue: queue_name)
      end
    end
end
