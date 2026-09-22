require "test_helper"

# Runs in its own process because the engine resolves its base controller class at load time.
class MissionControl::Jobs::ApiOnlyHostTest < ActionDispatch::IntegrationTest
  setup do
    skip "requires API_ONLY=1" unless ENV["API_ONLY"] == "1"
  end

  test "failed job page renders when the host base controller is ActionController::API" do
    FailingJob.perform_later(42)
    perform_enqueued_jobs_async
    job = ActiveJob.jobs.failed.last

    get mission_control_jobs.application_job_url(@application, job.job_id)
    assert_response :ok
    assert_select "turbo-frame#job-backtrace"
  end
end
