require "test_helper"

class MissionControl::Jobs::JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DummyJob.queue_as :queue_1
    @job = DummyJob.perform_later(42)
  end

  test "get job details" do
    get mission_control_jobs.application_job_url(@application, @job.job_id)
    assert_response :ok

    assert_includes response.body, @job.job_id
    assert_includes response.body, "queue_1"

    get mission_control_jobs.application_job_url(@application, @job.job_id, filter: { queue_name: "queue_1" })
    assert_response :ok

    assert_includes response.body, @job.job_id
    assert_includes response.body, "queue_1"
  end

  test "redirect to queue when job doesn't exist" do
    get mission_control_jobs.application_job_url(@application, @job.job_id + "0", filter: { queue_name: "queue_1" })
    assert_redirected_to mission_control_jobs.application_queue_path(@application, :queue_1)
  end

  test "get scheduled jobs" do
    DummyJob.set(wait: 3.minutes).perform_later
    DummyJob.set(wait: 1.minute).perform_later

    travel_to 2.minutes.from_now

    get mission_control_jobs.application_jobs_url(@application, :scheduled)

    assert_select "tr.job", 2
    assert_select "tr.job", /DummyJob\s+Enqueued 2 minutes ago\s+queue_1\s+in 1 minute/
    assert_select "tr.job", /DummyJob\s+Enqueued 2 minutes ago\s+queue_1\s+less than a minute ago/
  end
end
