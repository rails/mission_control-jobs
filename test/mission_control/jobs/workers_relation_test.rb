require "test_helper"

class MissionControl::Jobs::WorkersTest < ActiveSupport::TestCase
  setup do
    queue_adapter = ActiveJob::QueueAdapters::SolidQueueExt
    @workers_relation = MissionControl::Jobs::WorkersRelation.new(queue_adapter: queue_adapter)
  end

  test "set limit and offset" do
    assert_equal 0, @workers_relation.offset_value

    workers = @workers_relation.offset(10).limit(20)

    assert_equal 10, workers.offset_value
    assert_equal 20, workers.limit_value
  end
end
