require "test_helper"

class MissionControl::Jobs::BatchesRelationTest < ActiveSupport::TestCase
  class StubAdapter
    def initialize(count)
      @count = count
    end

    def count_batches(_batches_relation)
      @count
    end

    def fetch_batches(_batches_relation)
      []
    end
  end

  setup do
    @batches_relation = MissionControl::Jobs::BatchesRelation.new(queue_adapter: ActiveJob::Base.queue_adapter)
  end

  test "set limit and offset" do
    assert_equal 0, @batches_relation.offset_value

    batches = @batches_relation.offset(10).limit(20)

    assert_equal 10, batches.offset_value
    assert_equal 20, batches.limit_value
  end

  test "count is clamped into the pagination window" do
    batches = MissionControl::Jobs::BatchesRelation.new(queue_adapter: StubAdapter.new(5))

    assert_equal 5, batches.count
    assert_equal 2, batches.offset(3).limit(3).count
    assert_equal 0, batches.offset(10).limit(3).count
    assert batches.offset(10).limit(3).empty?
  end

  test "an internally capped count flows through when no limit is given" do
    batches = MissionControl::Jobs::BatchesRelation.new(queue_adapter: StubAdapter.new(Float::INFINITY))

    assert_equal Float::INFINITY, batches.count
  end
end
