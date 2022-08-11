module ActiveJob::QueueAdapters::AdapterTesting::RetryJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "retrying jobs raises an error for jobs that are not in a failed state" do
    10.times { DummyJob.perform_later }
    assert_raises ActiveJob::Errors::InvalidOperation do
      ActiveJob.jobs.retry_all
    end
  end

  test "retry all failed jobs" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    failed_jobs = ActiveJob.jobs.failed
    assert_not_empty failed_jobs
    failed_jobs.retry_all

    assert_empty failed_jobs
  end

  test "retry a single failed job" do
    FailingJob.perform_later
    perform_enqueued_jobs

    assert_not_empty ActiveJob.jobs.failed

    failed_job = ActiveJob.jobs.failed.last
    failed_job.retry

    assert_empty ActiveJob.jobs.failed
  end

  test "retrying a single job fails if the job does not exist" do
    FailingJob.perform_later
    perform_enqueued_jobs
    failed_job = ActiveJob.jobs.failed.last
    delete_all_jobs

    assert_raise ActiveJob::Errors::JobNotFoundError do
      failed_job.retry
    end
  end
end
