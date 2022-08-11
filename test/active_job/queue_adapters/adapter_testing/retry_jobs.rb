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
end
