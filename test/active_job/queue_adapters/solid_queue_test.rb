require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  test "supports batches only when the Solid Queue batch API is available" do
    assert ActiveJob::Base.queue_adapter.supports_batches?

    SolidQueue.stubs(:const_defined?).with(:Batch, false).returns(false)

    assert_not ActiveJob::Base.queue_adapter.supports_batches?
  end

  test "supports batches only when the Solid Queue batch migration has been run" do
    SolidQueue::Batch.stubs(:migrated?).returns(false)

    assert_not ActiveJob::Base.queue_adapter.supports_batches?
  end

  test "find a job by id applies the batch filter" do
    batch_1, job_1 = create_batch
    _batch_2, job_2 = create_batch

    batch_jobs = ActiveJob.jobs.where(batch_id: batch_1.id)

    assert_equal job_1.job_id, batch_jobs.find_by_id(job_1.job_id).job_id
    assert_nil batch_jobs.find_by_id(job_2.job_id)
  end

  test "counts jobs with a fixed number of queries however many batches are listed" do
    create_batch
    queries_for_one = capture_select_queries do
      ActiveJob::Base.queue_adapter.fetch_batches(batches_relation)
    end

    3.times { create_batch }
    queries = capture_select_queries do
      batches = ActiveJob::Base.queue_adapter.fetch_batches(batches_relation)
      assert_equal [ 1, 1, 1, 1 ], batches.pluck(:pending_jobs)
    end

    assert_equal queries_for_one.size, queries.size, queries.join("\n\n")
  end

  test "lists finished batches without live job-count subqueries" do
    batch, = create_batch
    batch.update!(finished_at: Time.current, completed_jobs: 1, failed_jobs: 0)

    queries = capture_select_queries do
      batches = ActiveJob::Base.queue_adapter.fetch_batches(batches_relation(status: :finished))
      assert_equal [ batch.id ], batches.pluck(:id)
      assert_equal [ 0 ], batches.pluck(:pending_jobs)
      assert_equal [ 1 ], batches.pluck(:completed_jobs)
    end

    assert_equal 1, queries.size, queries.join("\n\n")
    assert_no_match(/solid_queue_batch_executions|solid_queue_ready_executions|solid_queue_failed_executions/, queries.first)
  end

  test "never reports negative counts while a retry overlaps its previous attempt" do
    batch, job = create_batch
    previous_attempt = SolidQueue::Job.find_by(active_job_id: job.job_id)

    # A retry keeps its Active Job id, so Solid Queue doesn't count it as a new logical
    # job, but it gets its own tracking row while the previous attempt still has one.
    retry_attributes = previous_attempt.attributes.except("id", "created_at", "updated_at")
    SolidQueue::Job.create!(retry_attributes.merge("arguments" => previous_attempt.arguments.merge("executions" => 1)))

    assert_equal 1, batch.reload.total_jobs
    assert_equal 2, SolidQueue::BatchExecution.where(batch_id: batch.id).count

    attributes = ActiveJob::Base.queue_adapter.fetch_batches(batches_relation(status: :unfinished)).sole

    assert_equal 0, attributes[:completed_jobs]
    assert_equal 0.0, attributes[:progress_percentage]
    assert_includes 0..100, attributes[:progress_percentage]
  end

  test "caps batches count like job counts" do
    3.times { create_batch }

    original_limit = MissionControl::Jobs.internal_query_count_limit
    MissionControl::Jobs.internal_query_count_limit = 2

    assert_equal Float::INFINITY, ActiveJob::Base.queue_adapter.count_batches(batches_relation)
    assert_equal Float::INFINITY, ActiveJob::Base.queue_adapter.count_batches(batches_relation(status: :unfinished))
  ensure
    MissionControl::Jobs.internal_query_count_limit = original_limit
  end

  test "returns an exact batches count below the internal limit" do
    2.times { create_batch }

    original_limit = MissionControl::Jobs.internal_query_count_limit
    MissionControl::Jobs.internal_query_count_limit = 5

    assert_equal 2, ActiveJob::Base.queue_adapter.count_batches(batches_relation(status: :unfinished))
  ensure
    MissionControl::Jobs.internal_query_count_limit = original_limit
  end

  private
    def batches_relation(status: nil)
      MissionControl::Jobs::BatchesRelation.new(queue_adapter: ActiveJob::Base.queue_adapter, status: status)
    end

    def create_batch
      job = nil
      batch = SolidQueue::Batch.enqueue { job = DummyJob.perform_later }
      [ batch, job ]
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
