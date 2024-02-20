module ActiveJob::QueueAdapters::AdapterTesting::JobStatuses
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "job is failed?" do
    skip_unless_queue_adapter_supports_status :failed

    job = FailingJob.perform_later
    assert_not job.failed?

    perform_enqueued_jobs
    job = ActiveJob.jobs.failed.last

    assert job.failed?
  end
end
