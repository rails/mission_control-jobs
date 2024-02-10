module ActiveJob::QueueAdapters::AdapterTesting::DiscardJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "discard all failed jobs" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    failed_jobs = ActiveJob.jobs.failed
    assert_not_empty failed_jobs
    failed_jobs.discard_all

    assert_empty failed_jobs.reload

    perform_enqueued_jobs
    assert_equal 10, FailingJob.invocations.count # not retried
  end

  test "discard all pending jobs" do
    10.times { |index| DummyJob.perform_later(index) }

    pending_jobs = ApplicationJob.queues[:default].jobs.pending
    assert_not_empty pending_jobs
    pending_jobs.discard_all

    assert_empty pending_jobs.reload

    perform_enqueued_jobs
  end

  test "discard all failed withing a given page" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    failed_jobs = ActiveJob.jobs.failed.offset(2).limit(3)
    failed_jobs.discard_all

    assert_equal 7, ActiveJob.jobs.failed.count

    [ 0, 1, 5, 6, 7, 8, 9 ].each.with_index do |expected_argument, index|
      assert_equal [ expected_argument ], ActiveJob.jobs.failed[index].serialized_arguments
    end
  end

  test "discard only failed of a given class" do
    5.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }
    perform_enqueued_jobs

    ActiveJob.jobs.failed.where(job_class_name: "FailingJob").discard_all

    assert_empty ActiveJob.jobs.failed.where(job_class_name: "FailingJob")
    assert_equal 10, ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob").count
  end

  test "discard only failed of a given queue" do
    FailingJob.queue_as :queue_1
    FailingReloadedJob.queue_as :queue_2

    5.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }
    perform_enqueued_jobs
    ActiveJob.jobs.failed.where(queue_name: :queue_1).discard_all

    assert_empty ActiveJob.jobs.failed.where(job_class_name: "FailingJob")
    assert_equal 10, ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob").count
  end

  test "discard all pending withing a given page" do
    10.times { |index| DummyJob.perform_later(index) }

    pending_jobs = ApplicationJob.queues[:default].jobs.pending
    page_of_jobs = pending_jobs.offset(2).limit(3)
    page_of_jobs.discard_all

    assert_equal 7, pending_jobs.count

    [ 0, 1, 5, 6, 7, 8, 9 ].each.with_index do |expected_argument, index|
      assert_equal [ expected_argument ], pending_jobs[index].serialized_arguments
    end
  end

  test "discard a single failed job" do
    FailingJob.perform_later
    perform_enqueued_jobs

    assert_not_empty ActiveJob.jobs.failed

    failed_job = ActiveJob.jobs.failed.last
    failed_job.discard

    assert_empty ActiveJob.jobs.failed

    perform_enqueued_jobs
    assert_equal 1, FailingJob.invocations.count # not retried
  end

  test "discard a single pending job" do
    DummyJob.perform_later

    pending_jobs = ApplicationJob.queues[:default].jobs.pending
    assert_not_empty pending_jobs

    pending_job = pending_jobs.last
    pending_job.discard

    assert_empty pending_jobs.reload
  end
end
