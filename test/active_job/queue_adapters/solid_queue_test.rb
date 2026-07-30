require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  teardown do
    SolidQueue::Batch.destroy_all
  end

  test "supports batches only when the Solid Queue batch API is available" do
    SolidQueue::Batch
    assert ActiveJob::Base.queue_adapter.supports_batches?

    SolidQueue.stubs(:const_defined?).with(:Batch, false).returns(false)

    assert_not ActiveJob::Base.queue_adapter.supports_batches?
  end

  test "supports batches only when the Solid Queue batch schema is installed" do
    SolidQueue::Batch.stubs(:table_exists?).returns(false)

    assert_not ActiveJob::Base.queue_adapter.supports_batches?
  end

  test "find a job by id applies the batch filter" do
    batch_1, job_1 = create_batch
    _batch_2, job_2 = create_batch

    batch_jobs = ActiveJob.jobs.where(batch_id: batch_1.id)

    assert_equal job_1.job_id, batch_jobs.find_by_id(job_1.job_id).job_id
    assert_nil batch_jobs.find_by_id(job_2.job_id)
  end

  test "loads batches and their job counts in one query" do
    3.times { create_batch }

    queries = capture_select_queries do
      batches = ActiveJob::Base.queue_adapter.batches
      assert_equal [ 1, 1, 1 ], batches.pluck(:pending_jobs)
    end

    assert_equal 1, queries.size, queries.join("\n\n")
  end

  private
    def create_batch
      job = nil
      batch = SolidQueue::Batch.enqueue { job = DummyJob.perform_later }
      [ batch, job ]
    end

    def capture_select_queries
      queries = []
      subscriber = lambda do |*, payload|
        queries << payload[:sql] if payload[:sql].match?(/\ASELECT\b/i)
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
      queries
    end

    def queue_adapter
      :solid_queue
    end

    def perform_enqueued_jobs
      worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0.01)
      worker.mode = :inline
      worker.start
    end
end
