require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  private
    def queue_adapter
      :resque
    end

    def perform_enqueued_jobs
      @worker ||= Resque::Worker.new("*")
      @worker.work(0.0)
    end
end
