require "test_helper"

class MissionControl::Jobs::Server::SerializableTest < ActiveSupport::TestCase
  setup do
    @bc4_chicago = MissionControl::Jobs.applications[:bc4].servers[:resque_chicago]
    @hey = MissionControl::Jobs.applications[:hey].servers[:queue]
  end

  test "generate a global id for a server" do
    assert_equal "bc4:resque_chicago", @bc4_chicago.to_global_id
    assert_equal "hey:queue", @hey.to_global_id
  end

  test "locate a server for a global id" do
    assert_equal @bc4_chicago, MissionControl::Jobs::Server.from_global_id("bc4:resque_chicago")
    assert_equal @hey, MissionControl::Jobs::Server.from_global_id("hey:queue")
  end

  test "raise an error when trying to locate a missing server" do
    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("bc4:resque_paris")
    end

    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("backpack:resque_chicago")
    end

    assert_raises MissionControl::Jobs::Errors::ResourceNotFound do
      MissionControl::Jobs::Server.from_global_id("backpack")
    end
  end
end
