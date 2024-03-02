require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  private
    def queue_adapter
      :solid_queue
    end

    def perform_enqueued_jobs
      worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0.01)
      worker.mode = :inline
      worker.start
    end
end
