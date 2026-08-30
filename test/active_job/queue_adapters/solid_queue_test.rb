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

  private
    def queue_adapter
      :solid_queue
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
