require "test_helper"

class MissionControl::Jobs::ServerTest < ActiveSupport::TestCase
  setup do
    @application = MissionControl::Jobs.applications[:bc4]
  end

  test "activating a queue adapter" do
    current_adapter = ActiveJob::Base.queue_adapter
    new_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new
    server = MissionControl::Jobs::Server.new(name: "resque_chicago", queue_adapter: new_adapter, application: @application)

    assert_equal current_adapter, ActiveJob::Base.queue_adapter

    server.activating do
      @executed = true
      assert_equal new_adapter, ActiveJob::Base.queue_adapter
    end

    assert @executed
    assert_equal current_adapter, ActiveJob::Base.queue_adapter
  end
end
