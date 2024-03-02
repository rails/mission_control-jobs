require "test_helper"

class MissionControl::Jobs::JobsControllerTest < ActionDispatch::IntegrationTest
  test "retry job with invalid ID" do
    post mission_control_jobs.application_job_retry_url(@application, "unknown_id")
    assert_redirected_to mission_control_jobs.application_jobs_url(@application, :failed)
    follow_redirect!

    assert_select "article.is-danger", /Job with id 'unknown_id' not found/
  end

  test "retry jobs when there are multiple instances of the same job due to automatic retries" do
    job = AutoRetryingJob.perform_later

    # Wait until the job has been executed and retried
    perform_enqueued_jobs_async { sleep(1) }

    get mission_control_jobs.application_jobs_url(@application, :failed)
    assert_response :ok

    assert_select "tr.job", 1
    assert_select "tr.job", /AutoRetryingJob\s+Enqueued less than a minute ago\s+AutoRetryingJob::RandomError/

    post mission_control_jobs.application_job_retry_url(@application, job.job_id)
    assert_redirected_to mission_control_jobs.application_jobs_url(@application, :failed)
    follow_redirect!

    assert_select "article.is-danger", text: /Job with id '#{job.job_id}' not found/, count: 0
    assert_select "tr.job", 0
  end
end
