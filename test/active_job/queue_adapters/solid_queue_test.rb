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
