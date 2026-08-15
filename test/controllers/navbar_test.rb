require "test_helper"

class MissionControl::Jobs::NavbarTest < ActionDispatch::IntegrationTest
  teardown do
    MissionControl::Jobs.back_to_main_app_path = nil
  end

  test "back to main app link defaults to main_app.root_path" do
    get mission_control_jobs.application_queues_url(@application)
    assert_response :ok

    assert_select "a", text: "Back to main app" do |elements|
      assert_equal "/", URI.parse(elements.first["href"]).path
    end
  end

  test "back to main app link uses the configured path when set" do
    MissionControl::Jobs.back_to_main_app_path = "/admin"

    get mission_control_jobs.application_queues_url(@application)
    assert_response :ok

    assert_select "a[href=?]", "/admin", text: "Back to main app"
  end

  test "back to main app link is hidden when explicitly disabled" do
    MissionControl::Jobs.back_to_main_app_path = false

    get mission_control_jobs.application_queues_url(@application)
    assert_response :ok

    assert_select "a", text: "Back to main app", count: 0
  end
end
