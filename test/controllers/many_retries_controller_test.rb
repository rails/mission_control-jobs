# require_relative "../application_system_test_case.rb"
require "test_helper"

class MissionControl::Jobs::ManyRetriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    FailingJob.queue_as :queue_1
    @failed_job1 = FailingJob.perform_later(42)
    @failed_job2 = FailingJob.perform_later(43)
    @failed_job3 = FailingJob.perform_later(44)
    perform_enqueued_jobs_async
    @referer = mission_control_jobs.application_jobs_url(@application, :failed)
  end

  test "retries multiple selected failed jobs" do
    assert_difference -> { ActiveJob.jobs.failed.count }, -2 do
      post mission_control_jobs.application_many_retries_url(@application), params: {
        job_ids: [ @failed_job1.job_id, @failed_job2.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Retried 2 of 2 selected jobs", flash[:notice]
    assert_equal 2, ActiveJob.jobs.pending.count
    assert_equal [ @failed_job1.job_id, @failed_job2.job_id ].sort, ActiveJob.jobs.pending.map(&:job_id).sort
  end

  test "handles mix of failed and non-failed jobs" do
    @failed_job2.retry
    perform_enqueued_jobs_async

    assert_difference -> { ActiveJob.jobs.failed.count }, -2 do
      post mission_control_jobs.application_many_retries_url(@application), params: {
        job_ids: [ @failed_job1.job_id, @failed_job2.job_id, @failed_job3.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Retried 2 of 3 selected jobs", flash[:notice]
    assert_equal 3, ActiveJob.jobs.pending.count
    assert_equal [ @failed_job1.job_id, @failed_job2.job_id, @failed_job3.job_id ].sort, ActiveJob.jobs.pending.map(&:job_id).sort
  end

  test "handles non-existent job IDs gracefully" do
    assert_difference -> { ActiveJob.jobs.failed.count }, -1 do
      post mission_control_jobs.application_many_retries_url(@application), params: {
        job_ids: [ nil, "non_existent_id", @failed_job1.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Retried 1 of 2 selected jobs", flash[:notice]
    assert_equal 1, ActiveJob.jobs.pending.count
    assert_equal [ @failed_job1.job_id ].sort, ActiveJob.jobs.pending.map(&:job_id).sort
  end

  test "handles empty job IDs array" do
    assert_no_difference -> { ActiveJob.jobs.failed.count } do
      post mission_control_jobs.application_many_retries_url(@application), params: {
        job_ids: []
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Retried 0 of 0 selected jobs", flash[:notice]
    assert_equal 0, ActiveJob.jobs.pending.count
  end
end
