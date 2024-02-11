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

  test "job is scheduled_enqueue_delayed?" do
    skip_unless_queue_adapter_supports_status :scheduled

    DummyJob.set(wait: 5.minute).perform_later
    job = ActiveJob.jobs.scheduled.last
    refute job.scheduled_enqueue_delayed?

    travel 5.minute + MissionControl::Jobs.scheduled_job_delay_threshold + 1.second

    assert job.scheduled_enqueue_delayed?
  end

  test "job with configured scheduled_job_delay_threshold is scheduled_enqueue_delayed?" do
    skip_unless_queue_adapter_supports_status :scheduled

    begin
      original_threshold = MissionControl::Jobs.scheduled_job_delay_threshold
      MissionControl::Jobs.scheduled_job_delay_threshold = 3.minutes

      DummyJob.set(wait: 5.minute).perform_later
      job = ActiveJob.jobs.scheduled.last
      refute job.scheduled_enqueue_delayed?

      travel 5.minute + MissionControl::Jobs.scheduled_job_delay_threshold + 1.second

      assert job.scheduled_enqueue_delayed?
    ensure
      MissionControl::Jobs.scheduled_job_delay_threshold = original_threshold
    end
  end

end
