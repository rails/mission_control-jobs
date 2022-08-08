module ActiveJob::QueueAdapters::AdapterTesting
  extend ActiveSupport::Concern

  included do
    include Queues

    setup do
      ApplicationJob.queue_adapter = queue_adapter
    end
  end

  private
    # Template method to override with the adapter to test.
    #
    # E.g: +:resque+, +:sidekiq+
    def queue_adapter
      raise NotImplementedError
    end
end
