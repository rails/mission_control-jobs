require "test_helper"

class MissionControl::Jobs::NavigationHelperTest < ActionView::TestCase
  tests MissionControl::Jobs::NavigationHelper

  setup do
    @original_back_to_main_app_path = MissionControl::Jobs.back_to_main_app_path
  end

  teardown do
    MissionControl::Jobs.back_to_main_app_path = @original_back_to_main_app_path
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
end
