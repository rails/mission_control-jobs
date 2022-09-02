# TODO: These should be moved to +ActiveJob::Core+ and related concerns
# when upstreamed.
module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    attr_accessor :last_execution_error
    attr_reader :serialized_arguments
    thread_cattr_accessor :current_queue_adapter
  end

  class_methods do
    def queue_adapter
      current_queue_adapter || super
    end

    def queue_adapter=(value)
      super.tap do
        queue_adapter.activate
      end
    end
  end

  def retry
    ActiveJob.jobs.failed.retry_job(self)
  end
end
