require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end
  
  test "filter by error when using multiple filters" do
    # This test specifically verifies the fix for duplicate table alias issue
    FailingJob.perform_later("Duplicate error test")
    perform_enqueued_jobs
    
    # Apply multiple filters that would cause joins, which previously caused the PG::DuplicateAlias error
    jobs = ActiveJob.jobs.failed.where(job_class_name: "FailingJob", error: "Duplicate").to_a
    
    # If the fix works, this should run without error and return the correct job
    assert_equal 1, jobs.length
    assert_includes jobs.first.error, "Duplicate error test"
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
