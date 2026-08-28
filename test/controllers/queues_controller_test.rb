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

    assert_select "thead th", "Queue"
    assert_select "thead th", "Pending jobs"

    assert_select "tbody tr", 1
    assert_select "tbody td", "default"
    assert_select "tbody td", "1"
  end

  test "turbo prefetch is disabled" do
    get mission_control_jobs.application_queues_url(@application)

    assert_select %(meta[name="turbo-prefetch"][content="false"])
  end
end
