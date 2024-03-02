module ActiveJob::QueueAdapters::AdapterTesting::DispatchJobs
  extend ActiveSupport::Testing::Declarative

  test "dispatch blocked job immediately" do
    10.times { |index| BlockingJob.perform_later(index * 0.1.seconds) }

    # Given, there is one pending and the others are blocked
    pending_jobs = ActiveJob.jobs.pending
    assert_equal 1, pending_jobs.size
    blocked_jobs = ActiveJob.jobs.blocked
    assert_equal 9, blocked_jobs.size

    blocked_jobs.each(&:dispatch)

    # Then, all blocked jobs are pending
    assert_empty blocked_jobs.reload
    assert_equal 10, pending_jobs.reload.size
  end
end
