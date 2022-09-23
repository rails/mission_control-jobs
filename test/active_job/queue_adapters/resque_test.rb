require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  test "jorge" do
    10.times { |index| FailingJob.perform_later(index) }
    5.times { |index| FailingReloadedJob.perform_later(index) }
    perform_enqueued_jobs

    assert_equal 15, ActiveJob.jobs.failed.count

    failed_jobs = ActiveJob.jobs.failed.where(job_class: "FailingReloadedJob")
    failed_jobs.retry_all

    assert_equal 10, ActiveJob.jobs.failed.count

    assert_not ActiveJob.jobs.failed.any? { |job| job.is_a?(FailingReloadedJob) }

    perform_enqueued_jobs
    assert_equal 1 * 10, FailingJob.invocations.count
    assert_equal 2 * 5, FailingReloadedJob.invocations.count
  end


  private
    def queue_adapter
      :resque
    end

    def perform_enqueued_jobs
      @worker ||= Resque::Worker.new("*")
      @worker.work(0.0)
    end
end
