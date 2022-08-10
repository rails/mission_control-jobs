module ActiveJob::QueueAdapters::AdapterTesting::CountJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "check if there are pending jobs" do
    assert_empty ApplicationJob.jobs.pending

    DummyJob.perform_later

    assert_not_empty ApplicationJob.jobs.pending
  end

  test "count pending jobs" do
    assert_equal 0, ApplicationJob.jobs.pending.count

    3.times { DummyJob.perform_later }

    assert_equal 3, ApplicationJob.jobs.pending.count
  end

  test "count the pending jobs of a given class" do
    [ DummyJob, DummyJob ].each { |job_class| job_class.queue_as :default }
    5.times { DummyJob.perform_later }
    10.times { DummyReloadedJob.perform_later }

    assert_equal 5, ApplicationJob.jobs.where(queue: "default", job_class: "DummyJob").count
    assert_equal 10, ApplicationJob.jobs.where(queue: "default", job_class: "DummyReloadedJob").count
  end

  test "count the pending jobs in a given queue" do
    DummyJob.queue_as :default
    5.times { DummyJob.perform_later }
    DummyJob.queue_as :other_queue
    3.times { DummyJob.perform_later }

    assert_equal 5, ApplicationJob.jobs.where(queue: "default").count
    assert_equal 3, ApplicationJob.jobs.where(queue: "other_queue").count
    assert_equal 3, ApplicationJob.jobs.where(queue: :other_queue).count
  end

  test "check if there are failed jobs" do
    assert_empty ApplicationJob.jobs.failed

    FailingJob.perform_later
    perform_enqueued_jobs

    assert_not_empty ApplicationJob.jobs.failed
  end

  test "count failed jobs" do
    assert_equal 0, ApplicationJob.jobs.failed.count

    3.times { FailingJob.perform_later }
    perform_enqueued_jobs

    assert_equal 3, ApplicationJob.jobs.failed.count
  end

  test "count failed jobs of a given class" do
    5.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }

    perform_enqueued_jobs

    assert 5, ApplicationJob.jobs.failed.where(job_class: "FailingJob").count
    assert 10, ApplicationJob.jobs.failed.where(job_class: "FailingReloadedJob").count
  end

  test "count with offset and limit" do
    assert_equal 0, ApplicationJob.jobs.failed.count

    10.times { FailingJob.perform_later }
    perform_enqueued_jobs

    assert_equal 7, ApplicationJob.jobs.failed.offset(3).count
    assert_equal 2, ApplicationJob.jobs.failed.limit(2).count
    assert_equal 2, ApplicationJob.jobs.failed.offset(3).limit(2).count
    assert_equal 3, ApplicationJob.jobs.failed.offset(7).limit(10).count
  end
end
