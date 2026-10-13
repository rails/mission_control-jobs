require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  test "expose the raw error when the failed execution error can't be parsed" do
    FailingJob.perform_later
    perform_enqueued_jobs

    SolidQueue::FailedExecution.update_all("error = 'RuntimeError: This always fails!'")

    execution_error = ActiveJob.jobs.failed.last.last_execution_error

    assert_equal "", execution_error.error_class
    assert_equal "RuntimeError: This always fails!", execution_error.message
    assert_empty execution_error.backtrace
  end

  test "fetching queues issues a single ready executions count for all queues" do
    create_queues "queue_1", "queue_2", "queue_3"

    queries = capture_sql { ActiveJob.queues.each(&:size) }
    ready_execution_counts = queries.count { |sql| sql.match?(/SELECT COUNT.*solid_queue_ready_executions/im) }

    assert_equal 1, ready_execution_counts
  end

  test "filter jobs by scheduled_at and enqueued_at natively" do
    DummyJob.set(wait: 30.minutes).perform_later(1)
    DummyJob.set(wait: 3.hours).perform_later(2)
    DummyJob.perform_later(3)
    FailingJob.perform_later(4)
    perform_enqueued_jobs

    scheduled_soon = ActiveJob.jobs.scheduled.where(scheduled_at: Time.now..1.hour.from_now)
    assert_not scheduled_soon.filtering_needed?
    assert_equal [ [ 1 ] ], scheduled_soon.map(&:serialized_arguments)

    enqueued_now = ActiveJob.jobs.failed.where(enqueued_at: 1.minute.ago..)
    assert_not enqueued_now.filtering_needed?
    assert_equal [ [ 4 ] ], enqueued_now.map(&:serialized_arguments)
    assert_empty ActiveJob.jobs.failed.where(enqueued_at: ..1.minute.ago)

    assert_equal 1, ActiveJob.jobs.finished.where(enqueued_at: 1.minute.ago..).count
    assert_empty ActiveJob.jobs.finished.where(scheduled_at: 1.hour.from_now..)
  end

  test "bulk discard and retry act on the same failed jobs that the relation lists" do
    relations = {
      "all" => -> { ActiveJob.jobs.failed },
      "by class" => -> { ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob") },
      "by queue" => -> { ActiveJob.jobs.failed.where(queue_name: :queue_1) },
      "by enqueued at" => -> { ActiveJob.jobs.failed.where(enqueued_at: ..30.minutes.ago) },
      "page" => -> { ActiveJob.jobs.failed.offset(2).limit(3) },
      "filtered page" => -> { ActiveJob.jobs.failed.where(job_class_name: "FailingJob", enqueued_at: ..30.minutes.ago).offset(1).limit(2) }
    }

    %i[ discard_all retry_all ].each do |operation|
      relations.each do |description, relation|
        delete_all_jobs
        enqueue_failed_jobs
        all_job_ids = ActiveJob.jobs.failed.map(&:job_id)
        listed_job_ids = relation.call.map(&:job_id)
        assert_not_empty listed_job_ids

        relation.call.public_send(operation)

        assert_equal (all_job_ids - listed_job_ids).sort, ActiveJob.jobs.failed.map(&:job_id).sort, "#{operation} #{description}"
        if operation == :retry_all
          assert_equal listed_job_ids.sort, ActiveJob.jobs.pending.map(&:job_id).sort, "#{operation} #{description}"
        end
      end
    end
  end

  test "bulk discard and retry don't load the failed executions" do
    enqueue_failed_jobs

    [ ActiveJob.jobs.failed.where(job_class_name: "FailingJob"), ActiveJob.jobs.failed.offset(1).limit(2) ].each do |jobs|
      instantiated = capture_instantiated_records { jobs.retry_all }
      assert_not_includes instantiated, "SolidQueue::FailedExecution", "retry_all #{jobs}"

      instantiated = capture_instantiated_records { jobs.discard_all }
      assert_not_includes instantiated, "SolidQueue::FailedExecution", "discard_all #{jobs}"
    end

    assert_empty capture_instantiated_records { ActiveJob.jobs.failed.discard_all }
    assert_empty ActiveJob.jobs.failed
  end

  test "discard all jobs with a status in batches" do
    3.times { |index| DummyJob.set(wait: 1.hour).perform_later(index) }
    DummyJob.perform_later

    ActiveJob.jobs.scheduled.discard_all

    assert_empty ActiveJob.jobs.scheduled
    assert_equal 1, ActiveJob.jobs.pending.count
  end

  test "supports batches only when the Solid Queue batch API is available" do
    assert ActiveJob::Base.queue_adapter.supports_batches?

    SolidQueue.stubs(:const_defined?).returns(false)

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

  test "counts the jobs of every batch listed with the same three queries" do
    4.times { create_batch }

    queries = capture_select_queries do
      batches = ActiveJob::Base.queue_adapter.fetch_batches(batches_relation)
      assert_equal [ 0, 0, 0, 0 ], batches.pluck(:failed_jobs)
      assert_equal [ 0.0, 0.0, 0.0, 0.0 ], batches.pluck(:progress_percentage)
    end

    assert_equal 3, queries.size, queries.join("\n\n")
  end

  test "breaks jobs down by status for a single batch" do
    batch, = create_batch

    attributes = ActiveJob::Base.queue_adapter.find_batch(batch.id)

    assert_equal 1, attributes[:pending_jobs]
    assert_equal [ 0, 0, 0, 0 ], attributes.values_at(:failed_jobs, :in_progress_jobs, :blocked_jobs, :scheduled_jobs)
  end

  test "lists finished batches without counting their jobs" do
    batch, = create_batch
    batch.update!(finished_at: Time.current, completed_jobs: 1, failed_jobs: 0)

    queries = capture_select_queries do
      batches = ActiveJob::Base.queue_adapter.fetch_batches(batches_relation(status: :finished))
      assert_equal [ batch.id ], batches.pluck(:id)
      assert_equal [ 1 ], batches.pluck(:completed_jobs)
      assert_equal [ 100.0 ], batches.pluck(:progress_percentage)
    end

    assert_equal 1, queries.size, queries.join("\n\n")
    assert_no_match(/solid_queue_batch_executions|solid_queue_ready_executions|solid_queue_failed_executions/, queries.first)
  end

  test "never reports negative counts while a retry overlaps its previous attempt" do
    batch, job = create_batch
    previous_attempt = SolidQueue::Job.find_by(active_job_id: job.job_id)
    enqueue_retry_of previous_attempt

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
    finished, = create_batch
    finished.update!(finished_at: Time.current)

    original_limit = MissionControl::Jobs.internal_query_count_limit
    MissionControl::Jobs.internal_query_count_limit = 5

    assert_equal 3, ActiveJob::Base.queue_adapter.count_batches(batches_relation)
    assert_equal 2, ActiveJob::Base.queue_adapter.count_batches(batches_relation(status: :unfinished))
    assert_equal 1, ActiveJob::Base.queue_adapter.count_batches(batches_relation(status: :finished))
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

    def enqueue_retry_of(job)
      attributes = job.attributes.except("id", "created_at", "updated_at")
      SolidQueue::Job.create!(attributes.merge("arguments" => job.arguments.merge("executions" => 1)))
    end

    def queue_adapter
      :solid_queue
    end

    def enqueue_failed_jobs
      FailingJob.queue_as :queue_1
      FailingReloadedJob.queue_as :queue_2
      5.times { |index| FailingJob.perform_later(index) }
      5.times { |index| FailingReloadedJob.perform_later(index) }
      perform_enqueued_jobs

      SolidQueue::Job.where(id: SolidQueue::Job.order(:id).ids.values_at(1, 3, 5, 7, 9)).update_all(created_at: 1.hour.ago)
    end

    def capture_instantiated_records
      class_names = []
      subscriber = ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*, payload|
        class_names << payload[:class_name]
      end
      yield
      class_names.uniq
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def capture_sql
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached]
      end
      yield
      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def perform_enqueued_jobs
      worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0.01)
      worker.mode = :inline
      worker.start
    end
end
