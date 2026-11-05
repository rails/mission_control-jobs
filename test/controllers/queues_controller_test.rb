require "test_helper"

class MissionControl::Jobs::QueuesControllerTest < ActionDispatch::IntegrationTest
  test "redirect to queues index when queue doesn't exist" do
    get mission_control_jobs.application_queue_url(@application, "missing_queue")
    assert_redirected_to mission_control_jobs.application_queues_url(@application)
    follow_redirect!

    assert_select "article.is-danger", /Queue 'missing_queue' not found/
  end

  test "get queues" do
    job = DummyJob.perform_later(42)

    get mission_control_jobs.application_queues_url(@application)

    assert_select "p", "1 pending job across 1 queue"
    assert_select "thead th", "Queue"
    assert_select "thead th", "Pending jobs"

    assert_select "tbody tr", 1
    assert_select "tbody td", "default"
    assert_select "tbody td", "1"
  end

  test "truncate long job arguments in the queue's job list" do
    job = DummyJob.perform_later("a" * 1000)

    get mission_control_jobs.application_queue_url(@application, "default")
    assert_response :ok
    assert_select "tr.job", /a{297}\.\.\./
    assert_no_match(/a{298}/, response.body)

    get mission_control_jobs.application_job_url(@application, job.job_id)
    assert_response :ok
    assert_includes response.body, "a" * 1000
  end

  test "pause and resume a queue whose name has a dot" do
    create_queues "mailers.high"

    get mission_control_jobs.application_queues_url(@application)
    post css_select("form:has(button:contains('Pause'))").first["action"]
    assert_redirected_to mission_control_jobs.application_queues_url(@application)
    assert SolidQueue::Queue.find_by_name("mailers.high").paused?

    get mission_control_jobs.application_queues_url(@application)
    delete css_select("form:has(button:contains('Resume'))").first["action"]
    assert_redirected_to mission_control_jobs.application_queues_url(@application)
    assert_not SolidQueue::Queue.find_by_name("mailers.high").paused?
  end

  test "turbo prefetch is disabled" do
    get mission_control_jobs.application_queues_url(@application)

    assert_select %(meta[name="turbo-prefetch"][content="false"])
  end
end
