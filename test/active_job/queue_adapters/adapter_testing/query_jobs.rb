module ActiveJob::QueueAdapters::AdapterTesting::QueryJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "instantiate jobs" do
    FailingJob.perform_later(123)
    perform_enqueued_jobs

    job = ActiveJob.jobs.failed.last

    assert_equal [ 123 ], job.serialized_arguments
    assert_job_proxy FailingJob, job
    assert job.job_id
  end

  test "jobs carry information on the last execution error" do
    FailingJob.perform_later
    perform_enqueued_jobs

    execution_error = ActiveJob.jobs.failed.last.last_execution_error

    assert_equal "RuntimeError", execution_error.error_class
    assert_equal "This always fails!", execution_error.message
    assert_not_empty execution_error.backtrace
  end

  test "enumerable lists of jobs" do
    10.times { FailingJob.perform_later }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.to_a

    assert_equal 10, jobs.size
    jobs.each do |job|
      assert_job_proxy FailingJob, job
    end

    assert jobs.find { |job| assert_job_proxy FailingJob, job }
  end

  test "enumerate jobs with limit without offset" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.limit(2).to_a
    assert_equal 2, jobs.size
    assert_equal [ 0 ], jobs[0].serialized_arguments
    assert_equal [ 1 ], jobs[1].serialized_arguments
  end

  test "enumerate jobs with offset without limit" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.offset(2).to_a
    assert_equal 8, jobs.size
    assert_equal [ 2 ], jobs[0].serialized_arguments
    assert_equal [ 9 ], jobs[7].serialized_arguments
  end

  test "enumerate jobs with offset and limit" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.offset(2).limit(2).to_a
    assert_equal 2, jobs.size
    assert_equal [ 2 ], jobs[0].serialized_arguments
    assert_equal [ 3 ], jobs[1].serialized_arguments
  end

  test "enumerate jobs when limit is greater than the available set" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.limit(1000).to_a
    assert_equal 10, jobs.size
  end

  test "enumerate jobs when offset is out of range" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = ActiveJob.jobs.failed.offset(1000).to_a
    assert_empty jobs
  end

  test "fetch failed jobs when pagination kicks in" do
    10.times { |index| WithPaginationFailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = WithPaginationFailingJob.jobs.failed.to_a
    assert_equal 10, jobs.size

    jobs.each.with_index do |job, index|
      assert_job_proxy WithPaginationFailingJob, job
      assert [ index ], job.serialized_arguments[0]
    end
  end

  test "fetch jobs when pagination kicks in with offset and limit" do
    10.times { |index| WithPaginationFailingJob.perform_later(index) }
    perform_enqueued_jobs

    jobs = WithPaginationFailingJob.jobs.failed.offset(2).limit(3).to_a
    assert_equal 3, jobs.size

    assert_equal [ 2 ], jobs[0].serialized_arguments
    assert_equal [ 4 ], jobs[2].serialized_arguments
  end

  test "fetch pending jobs when pagination kicks in and the first pages are empty due to filtering" do
    10.times { |index| WithPaginationDummyJob.perform_later(index) }
    4.times { |index| WithPaginationFailingJob.perform_later(index) }

    jobs = ActiveJob.jobs.pending.where(queue_name: :default, job_class_name: 'WithPaginationDummyJob').to_a
    assert_equal 10, jobs.size
  end

  test "fetch jobs in a given queue" do
    DummyJob.queue_as :queue_1
    3.times { DummyJob.perform_later }
    DummyJob.queue_as :queue_2
    5.times { DummyJob.perform_later }

    assert_equal 3, ActiveJob.jobs.pending.where(queue_name: "queue_1").to_a.length
    assert_equal 5, ActiveJob.jobs.pending.where(queue_name: "queue_2").to_a.length
  end

  test "fetch job classes in the first jobs" do
    3.times { DummyJob.perform_later }
    10.times { DummyReloadedJob.perform_later }
    2.times { DummyJob.perform_later }
    15.times { DummyReloadedJob.perform_later }

    assert_equal [ "DummyJob", "DummyReloadedJob" ], ActiveJob.queues[:default].jobs.pending.job_class_names
  end
end
