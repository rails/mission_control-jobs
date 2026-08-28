require "test_helper"

class MissionControl::Jobs::HostRouteHelpersTest < ActionDispatch::IntegrationTest
  test "host route helpers used by the base controller resolve against the host app's routes" do
    get mission_control_jobs.application_queues_url(@application, require_authentication: true)
    assert_redirected_to "/session/new"
  end

  test "route helpers defined by both the host app and the engine keep resolving to the engine's" do
    assert_includes MissionControl::Jobs::HostRouteHelpers.instance_methods, :new_session_path
    assert_not_includes MissionControl::Jobs::HostRouteHelpers.instance_methods, :root_path
  end

  test "host route helpers are redefined when routes reload" do
    Rails.application.reload_routes!

    assert_includes MissionControl::Jobs::HostRouteHelpers.instance_methods, :new_session_path
    get mission_control_jobs.application_queues_url(@application, require_authentication: true)
    assert_redirected_to "/session/new"
  end
end
