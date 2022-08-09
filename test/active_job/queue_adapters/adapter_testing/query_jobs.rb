module ActiveJob::QueueAdapters::AdapterTesting::QueryJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "instantiate jobs" do
    FailingJob.perform_later(123)
    perform_enqueued_jobs

    job = ApplicationJob.jobs.failed.last

    assert_equal [ 123 ], job.serialized_arguments
    assert_job_proxy FailingJob, job
    assert job.job_id
  end

  test "jobs carry information on the last execution error" do
    FailingJob.perform_later
    perform_enqueued_jobs

    execution_error = ApplicationJob.jobs.failed.last.last_execution_error

    assert_equal "RuntimeError", execution_error.error_class
    assert_equal "This always fails!", execution_error.message
    assert_not_empty execution_error.backtrace
  end

  test "enumerable lists of jobs" do
    10.times { FailingJob.perform_later }
    perform_enqueued_jobs

    jobs = ApplicationJob.jobs.failed.to_a

    assert_equal 10, jobs.size
    jobs.each do |job|
      assert_job_proxy FailingJob, job
    end

    assert jobs.find { |job| assert_job_proxy FailingJob, job }
  end

  test "fetch failed jobs when pagination kicks in" do
    WithPaginationFailingJob = Class.new(FailingJob)
    WithPaginationFailingJob.default_page_size = 2

    10.times { |index| WithPaginationFailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = WithPaginationFailingJob.jobs.failed.to_a
    assert_equal 10, jobs.size

    jobs.each.with_index do |job, index|
      assert_job_proxy WithPaginationFailingJob, job
      assert [ index ], job.serialized_arguments[0]
    end
  end

  test "fetch jobs in a given queue" do
    DummyJob.queue_as :queue_1
    3.times { DummyJob.perform_later }
    DummyJob.queue_as :queue_2
    5.times { DummyJob.perform_later }

    assert_equal 3, ApplicationJob.jobs.where(queue: "queue_1").to_a.length
    assert_equal 5, ApplicationJob.jobs.where(queue: "queue_2").to_a.length
  end
end
