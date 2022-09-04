require "test_helper"

class MissionControl::Jobs::ServerTest < ActiveSupport::TestCase
  test "activate changes Active Job's current queue adapter" do
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    server = MissionControl::Jobs::Server.new(name: "foo", queue_adapter: queue_adapter)

    assert_changes -> { ActiveJob::Base.current_queue_adapter }, to: queue_adapter do
      server.activate
    end
  end
end

