require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  test "supports queue pausing when ResquePauseHelper is defined" do
    assert ActiveJob::Base.queue_adapter.supports_queue_pausing?
  end

  test "does not support queue pausing when ResquePauseHelper is not defined" do
    emulating_resque_pause_gem_absence do
      assert_not ActiveJob::Base.queue_adapter.supports_queue_pausing?
    end
  end

  test "find a failed job deep in the list" do
    10.times { |index| WithPaginationFailingJob.perform_later(index) }
    perform_enqueued_jobs
    oldest_job, newest_job = WithPaginationFailingJob.jobs.failed.to_a.values_at(-1, 0)

    found_job = WithPaginationFailingJob.jobs.failed.find_by_id(oldest_job.job_id)
    assert_equal [ 0 ], found_job.serialized_arguments
    assert_equal 0, found_job.position

    assert_equal [ 9 ], WithPaginationFailingJob.jobs.failed.find_by_id(newest_job.job_id).serialized_arguments
    assert_nil WithPaginationFailingJob.jobs.failed.limit(9).find_by_id(oldest_job.job_id)
    assert_nil WithPaginationFailingJob.jobs.failed.offset(1).find_by_id(newest_job.job_id)
    assert_equal [ 0 ], WithPaginationFailingJob.jobs.failed.offset(9).find_by_id(oldest_job.job_id).serialized_arguments
    assert_nil WithPaginationFailingJob.jobs.failed.find_by_id("1234-6789")
  end

  test "find a pending job deep in the queue" do
    jobs = 10.times.map { |index| WithPaginationDummyJob.perform_later(index) }
    pending_jobs = WithPaginationDummyJob.jobs.pending.where(queue_name: :default)

    found_job = pending_jobs.find_by_id(jobs.last.job_id)
    assert_equal [ 9 ], found_job.serialized_arguments
    assert_equal 9, found_job.position

    assert_nil pending_jobs.limit(9).find_by_id(jobs.last.job_id)
    assert_nil pending_jobs.find_by_id("1234-6789")
  end

  private
    def emulating_resque_pause_gem_absence
      helper_const = Object.send(:remove_const, :ResquePauseHelper)
      yield
    ensure
      Object.const_set(:ResquePauseHelper, helper_const)
    end

    def queue_adapter
      :resque
    end

    def perform_enqueued_jobs
      @worker ||= Resque::Worker.new("*")
      @worker.work(0.0)
    end
end
