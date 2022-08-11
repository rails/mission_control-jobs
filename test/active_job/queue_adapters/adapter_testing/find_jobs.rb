module ActiveJob::QueueAdapters::AdapterTesting::FindJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "find a job by id" do
    DummyJob.queue_as(:queue_1)
    job = DummyJob.perform_later(1234)
    found_job = ActiveJob.queues[:queue_1].jobs.find(job.job_id)

    assert_job_proxy DummyJob, found_job
    assert_equal [ 1234 ], found_job.serialized_arguments
  end

  test "find returns nil when not found" do
    assert_nil ActiveJob.jobs.failed.find("1234-6789")
  end

  test "find! raises an error when the job is missing" do
    assert_raises ActiveJob::Errors::JobNotFoundError do
      ActiveJob.jobs.failed.find!("1234-6789")
    end
  end
end
