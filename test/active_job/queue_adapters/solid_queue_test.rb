require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  private
    def queue_adapter
      :solid_queue
    end

    def perform_enqueued_jobs
      worker = SolidQueue::Worker.new(queues: "*", threads: 3, polling_interval: 0)
      worker.mode = :inline
      worker.start
    end
end
