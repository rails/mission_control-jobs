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
end
