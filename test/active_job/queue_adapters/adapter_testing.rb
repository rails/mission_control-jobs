module ActiveJob::QueueAdapters::AdapterTesting
  extend ActiveSupport::Concern

  included do
    include CountJobs, QueryJobs, Queues, RetryJobs

    setup do
      ApplicationJob.queue_adapter = queue_adapter
    end
  end

  private
    # Returns the adapter to test.
    #
    # Template method to override in child classes.
    #
    # E.g: +:resque+, +:sidekiq+
    def queue_adapter
      raise NotImplementedError
    end

    # Perform the jobs in the queue.
    #
    # Template method to override in child classes.
    def perform_enqueued_jobs
      raise NotImplementedError
    end
end
