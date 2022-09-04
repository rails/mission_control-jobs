require "test_helper"

class MissionControl::Jobs::ApplicationsTest < ActiveSupport::TestCase
  setup do
    @applications = MissionControl::Jobs::Applications.new
  end

  test "register applications with job servers" do
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    @applications.add :bc4, chicago: queue_adapter

    server = @applications.first.servers.first
    assert_equal "chicago", server.name
    assert_equal queue_adapter, server.queue_adapter
  end

  test "find applications by their id" do
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    @applications.add "Basecamp 4", chicago: queue_adapter

    assert_equal "Basecamp 4", @applications["basecamp-4"].name
  end
end
