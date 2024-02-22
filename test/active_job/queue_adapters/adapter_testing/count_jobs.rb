module ActiveJob::QueueAdapters::AdapterTesting::CountJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "check if there are pending jobs" do
    assert_empty ActiveJob.jobs.pending

    DummyJob.perform_later

    assert_not_empty ActiveJob.jobs.pending
  end

  test "count pending jobs" do
    assert_equal 0, ActiveJob.jobs.pending.count

    3.times { DummyJob.perform_later }

    assert_equal 3, ActiveJob.jobs.pending.count
  end

  test "count the pending jobs of a given class" do
    5.times { DummyJob.perform_later }
    10.times { DummyReloadedJob.perform_later }

    assert_equal 5, ActiveJob.jobs.pending.where(queue_name: "default", job_class_name: "DummyJob").count
    assert_equal 10, ActiveJob.jobs.pending.where(queue_name: "default", job_class_name: "DummyReloadedJob").count
  end

  test "count the pending jobs in a given queue" do
    DummyJob.queue_as :default
    5.times { DummyJob.perform_later }
    DummyJob.queue_as :other_queue
    3.times { DummyJob.perform_later }

    assert_equal 8, ActiveJob.queues.sum(&:size)
    assert_equal 5, ActiveJob.jobs.pending.where(queue_name: "default").count
    assert_equal 3, ActiveJob.jobs.pending.where(queue_name: "other_queue").count
    assert_equal 3, ActiveJob.jobs.pending.where(queue_name: :other_queue).count

    assert_equal 5, ActiveJob.queues[:default].size
    assert_equal 3, ActiveJob.queues[:other_queue].size
    assert_equal 3, ActiveJob.queues["other_queue"].size
  end

  test "check if there are failed jobs" do
    assert_empty ActiveJob.jobs.failed

    FailingJob.perform_later
    perform_enqueued_jobs

    assert_not_empty ActiveJob.jobs.failed
  end

  test "count failed jobs" do
    assert_equal 0, ActiveJob.jobs.failed.count

    3.times { FailingJob.perform_later }
    perform_enqueued_jobs

    assert_equal 3, ActiveJob.jobs.failed.count
  end

  test "count failed jobs of a given class" do
    5.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }

    perform_enqueued_jobs

    assert 5, ActiveJob.jobs.failed.where(job_class_name: "FailingJob").count
    assert 10, ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob").count
  end

  test "count failed jobs of a given queue" do
    FailingJob.queue_as :queue_1
    FailingReloadedJob.queue_as :queue_2

    5.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }

    perform_enqueued_jobs

    assert 5, ActiveJob.jobs.failed.where(queue_name: :queue_1).count
    assert 10, ActiveJob.jobs.failed.where(queue_name: :queue_2).count
  end

  test "count failing jobs with offset and limit" do
    assert_equal 0, ActiveJob.jobs.failed.count

    10.times { FailingJob.perform_later }
    perform_enqueued_jobs

    assert_equal 7, ActiveJob.jobs.failed.offset(3).count
    assert_equal 2, ActiveJob.jobs.failed.limit(2).count
    assert_equal 2, ActiveJob.jobs.failed.offset(3).limit(2).count
    assert_equal 3, ActiveJob.jobs.failed.offset(7).limit(10).count
  end

  test "count failing jobs with offset, limit and job_class" do
    assert_equal 0, ActiveJob.jobs.failed.count

    10.times { FailingJob.perform_later }
    10.times { FailingReloadedJob.perform_later }
    perform_enqueued_jobs

    assert_equal 7, ActiveJob.jobs.failed.where(job_class_name: "FailingJob").offset(3).count
    assert_equal 2, ActiveJob.jobs.failed.where(job_class_name: "FailingJob").limit(2).count
    assert_equal 2, ActiveJob.jobs.failed.where(job_class_name: "FailingJob").offset(3).limit(2).count
    assert_equal 3, ActiveJob.jobs.failed.where(job_class_name: "FailingJob").offset(7).limit(10).count
  end

  test "count jobs with internal query count limit configured" do
    skip "Only Solid Queue supports internal query count limit" unless queue_adapter == :solid_queue

    begin
      original_limit = MissionControl::Jobs.internal_query_count_limit
      MissionControl::Jobs.internal_query_count_limit = 5
      assert_equal 0, ActiveJob.jobs.pending.count

      5.times { DummyJob.perform_later }
      assert_equal 5, ActiveJob.jobs.pending.count

      DummyJob.perform_later
      assert_equal Float::INFINITY, ActiveJob.jobs.pending.count
    ensure
      MissionControl::Jobs.internal_query_count_limit = original_limit
    end
  end
end
