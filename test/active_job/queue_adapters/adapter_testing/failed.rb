module ActiveJob::QueueAdapters::AdapterTesting::Failed
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

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
end
