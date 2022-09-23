require "test_helper"

class MissionControl::Jobs::Server::SerializableTest < ActiveSupport::TestCase
  setup do
    @bc3_chicago = MissionControl::Jobs.applications[:bc3].servers[:chicago]
    @hey = MissionControl::Jobs.applications[:hey].servers.first
  end

  test "generate a global id for a server" do
    assert_equal "bc3:chicago", @bc3_chicago.to_global_id
    assert_equal "hey", @hey.to_global_id
  end

  test "locate a server for a global id" do
    assert_equal @bc3_chicago, MissionControl::Jobs::Server.from_global_id("bc3:chicago")
    assert_equal @hey, MissionControl::Jobs::Server.from_global_id("hey")
  end

  test "raise an error when trying to locate a missing server" do
    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("bc3:paris")
    end

    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("backpack:chicago")
    end

    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("backpack")
    end
  end
end
