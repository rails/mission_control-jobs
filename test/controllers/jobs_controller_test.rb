require "test_helper"

class MissionControl::Jobs::JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DummyJob.queue_as :queue_1
  end

  test "get job details" do
    job = DummyJob.perform_later(42)

    get mission_control_jobs.application_job_url(@application, job.job_id)
    assert_response :ok

    assert_select "h1", /DummyJob\s+pending/
    assert_includes response.body, job.job_id
    assert_select "div.tag a", "queue_1"

    get mission_control_jobs.application_job_url(@application, job.job_id, filter: { queue_name: "queue_1" })
    assert_response :ok

    assert_select "h1", /DummyJob\s+pending/
    assert_includes response.body, job.job_id
    assert_select "div.tag a", "queue_1"
  end

  test "get jobs and job details when there are multiple instances of the same job due to automatic retries" do
    job = AutoRetryingJob.perform_later
    perform_enqueued_jobs_async

    # Wait until the job has been executed and retried
    sleep(1)

    get mission_control_jobs.application_jobs_url(@application, :finished)
    assert_response :ok

    assert_select "tr.job", 2
    assert_select "tr.job", /AutoRetryingJob\s+Enqueued less than a minute ago\s+default/

    get mission_control_jobs.application_job_url(@application, job.job_id)
    assert_response :ok

    assert_select "h1", /AutoRetryingJob\s+failed\s+/
    assert_includes response.body, job.job_id
    assert_select "div.is-danger", "failed"
  end

  test "redirect to queue when job doesn't exist" do
    job = DummyJob.perform_later(42)

    get mission_control_jobs.application_job_url(@application, job.job_id + "0", filter: { queue_name: "queue_1" })
    assert_redirected_to mission_control_jobs.application_queue_path(@application, :queue_1)
  end

  test "get scheduled jobs" do
    DummyJob.set(wait: 3.minutes).perform_later
    DummyJob.set(wait: 1.minute).perform_later

    travel_to 2.minutes.from_now

    get mission_control_jobs.application_jobs_url(@application, :scheduled)
    assert_response :ok

    assert_select "tr.job", 2
    assert_select "tr.job", /DummyJob\s+Enqueued 2 minutes ago\s+queue_1\s+in 1 minute/
    assert_select "tr.job", /DummyJob\s+Enqueued 2 minutes ago\s+queue_1\s+(1 minute ago|less than a minute ago)/
  end

  test "get scheduled jobs when some are delayed" do
    DummyJob.set(wait: 5.minutes).perform_later(37)
    DummyJob.set(wait: 7.minutes).perform_later(42)

    get mission_control_jobs.application_jobs_url(@application, :scheduled)
    assert_response :ok
    assert_select "tr.job", 2 do # lists two jobs
      assert_select "div.tag", text: /delayed/, count: 0 # no delayed tag
    end

    travel 5.minutes + MissionControl::Jobs.scheduled_job_delay_threshold + 1.second

    get mission_control_jobs.application_jobs_url(@application, :scheduled)
    assert_response :ok
    assert_select "tr.job", 2 do # lists two jobs
      assert_select "div.tag", text: /delayed/, count: 1 # total of one delayed tag
    end
  end
end
