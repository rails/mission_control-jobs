require "test_helper"

class MissionControl::Jobs::ManyDiscardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    FailingJob.queue_as :queue_1
    @failed_job1 = FailingJob.perform_later(42)
    @failed_job2 = FailingJob.perform_later(43)
    @failed_job3 = FailingJob.perform_later(44)
    perform_enqueued_jobs_async
    @referer = mission_control_jobs.application_jobs_url(@application, :failed)
  end

  test "discards multiple selected failed jobs" do
    assert_difference -> { ActiveJob.jobs.failed.count }, -2 do
      post mission_control_jobs.application_many_discards_url(@application), params: {
        job_ids: [ @failed_job1.job_id, @failed_job2.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Discarded 2 of 2 selected jobs", flash[:notice]
    assert_equal 1, ActiveJob.jobs.failed.count
    assert_equal [ @failed_job3.job_id ], ActiveJob.jobs.failed.map(&:job_id)
  end

  test "handles mix of failed and non-failed jobs" do
    @failed_job2.retry
    perform_enqueued_jobs_async

    assert_difference -> { ActiveJob.jobs.failed.count }, -1 do
      post mission_control_jobs.application_many_discards_url(@application), params: {
        job_ids: [ @failed_job1.job_id, @failed_job2.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Discarded 1 of 2 selected jobs", flash[:notice]
    assert_equal 1, ActiveJob.jobs.failed.count
    assert_equal [ @failed_job3.job_id ], ActiveJob.jobs.failed.map(&:job_id)
  end

  test "handles non-existent job IDs gracefully" do
    assert_difference -> { ActiveJob.jobs.failed.count }, -1 do
      post mission_control_jobs.application_many_discards_url(@application), params: {
        job_ids: [ nil, "non_existent_id", @failed_job1.job_id ]
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Discarded 1 of 2 selected jobs", flash[:notice]
    assert_equal 2, ActiveJob.jobs.failed.count
    assert_equal [ @failed_job2.job_id, @failed_job3.job_id ].sort, ActiveJob.jobs.failed.map(&:job_id).sort
  end

  test "handles empty job IDs array" do
    assert_no_difference -> { ActiveJob.jobs.failed.count } do
      post mission_control_jobs.application_many_discards_url(@application), params: {
        job_ids: []
      }, headers: { "HTTP_REFERER": @referer }
    end

    assert_redirected_to @referer
    assert_equal "Discarded 0 of 0 selected jobs", flash[:notice]
    assert_equal 3, ActiveJob.jobs.failed.count
    assert_equal [ @failed_job1.job_id, @failed_job2.job_id, @failed_job3.job_id ].sort, ActiveJob.jobs.failed.map(&:job_id).sort
  end
end
