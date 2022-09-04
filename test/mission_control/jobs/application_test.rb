require "test_helper"

class MissionControl::Jobs::ApplicationTest < ActiveSupport::TestCase
  setup do
    @application = MissionControl::Jobs::Application.new(name: "BC4")
  end

  test "register job servers" do
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    @application.add_servers chicago: queue_adapter

    server = @application.servers.first
    assert_equal "chicago", server.name
    assert_equal queue_adapter, server.queue_adapter
  end

  test "jobs servers can be found by name or slug" do
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    @application.add_servers "US east 1": queue_adapter
    assert_equal queue_adapter, @application.find_server("US east 1").queue_adapter
    assert_equal queue_adapter, @application.find_server("us-east-1").queue_adapter
  end
end
