require "test_helper"

class MissionControl::Jobs::QueuesControllerTest < ActionDispatch::IntegrationTest
  test "redirect to queues index when queue doesn't exist" do
    get mission_control_jobs.application_queue_url(@application, "missing_queue")
    assert_redirected_to mission_control_jobs.application_queues_url(@application)
    follow_redirect!

    assert_select "article.is-danger", /Queue 'missing_queue' not found/
  end
end
