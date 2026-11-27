require "test_helper"

class MissionControl::Jobs::NavigationHelperTest < ActionView::TestCase
  tests MissionControl::Jobs::NavigationHelper

  setup do
    @original_back_to_main_app_path = MissionControl::Jobs.back_to_main_app_path
    @original_page_title = MissionControl::Jobs.page_title
  end

  teardown do
    MissionControl::Jobs.back_to_main_app_path = @original_back_to_main_app_path
    MissionControl::Jobs.page_title = @original_page_title
  end

  test "returns configured back link destination when set" do
    MissionControl::Jobs.back_to_main_app_path = "/admin"

    stubs(:main_app).returns(stub(root_path: "/"))

    assert_equal "/admin", back_to_main_app_path
  end

  test "falls back to main app root path when no override is configured" do
    stubs(:main_app).returns(stub(root_path: "/"))

    assert_equal "/", back_to_main_app_path
  end

  test "returns nil when no override is configured and main app does not expose root path" do
    stubs(:main_app).returns(Object.new)

    assert_nil back_to_main_app_path
  end

  test "builds the default page title" do
    navigation(title: "Queues")

    assert_equal "Mission control - Queues", mission_control_page_title
  end

  test "uses the configured page title builder" do
    navigation(title: "Queues")
    MissionControl::Jobs.page_title = ->(title) { "#{title} - My App" }

    assert_equal "Queues - My App", mission_control_page_title
  end
end
