require "test_helper"

class MissionControl::Jobs::BasicAuthenticationTest < ActionDispatch::IntegrationTest
  test "unconfigured basic auth is closed" do
    with_http_basic_auth do
      get mission_control_jobs.application_queues_url(@application), headers: auth_headers("dev", "secret")
      assert_response :unauthorized
    end
  end

  test "fail to authenticate without credentials" do
    with_http_basic_auth(user: "dev", password: "secret") do
      get mission_control_jobs.application_queues_url(@application)
      assert_response :unauthorized
    end
  end

  test "fail to authenticate with wrong credentials" do
    with_http_basic_auth(user: "dev", password: "secret") do
      get mission_control_jobs.application_queues_url(@application), headers: auth_headers("dev", "wrong")
      assert_response :unauthorized
    end
  end

  test "authenticate with correct credentials" do
    with_http_basic_auth(user: "dev", password: "secret") do
      get mission_control_jobs.application_queues_url(@application), headers: auth_headers("dev", "secret")
      assert_response :ok
    end
  end

  private
    def with_http_basic_auth(enabled: true, user: nil, password: nil)
      previous_enabled, MissionControl::Jobs.http_basic_auth_enabled = MissionControl::Jobs.http_basic_auth_enabled, enabled
      previous_user, MissionControl::Jobs.http_basic_auth_user = MissionControl::Jobs.http_basic_auth_user, user
      previous_password, MissionControl::Jobs.http_basic_auth_password = MissionControl::Jobs.http_basic_auth_password, password
      yield
    ensure
      MissionControl::Jobs.http_basic_auth_enabled = previous_enabled
      MissionControl::Jobs.http_basic_auth_user = previous_user
      MissionControl::Jobs.http_basic_auth_password = previous_password
    end

    def auth_headers(user, password)
      { Authorization: ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
    end
end
