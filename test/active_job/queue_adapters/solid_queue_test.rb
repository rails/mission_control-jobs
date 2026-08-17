require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  test "counts all statuses in one storage query" do
    ActiveJob.jobs.counts_by_status(statuses: ActiveJob::JobsRelation::STATUSES)
    queries = []

    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      ActiveJob.jobs.counts_by_status(statuses: ActiveJob::JobsRelation::STATUSES)
    end

    assert_equal 1, queries.count { |query| query.match?(/\ASELECT/) }
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
