require "test_helper"

class ActiveJob::WorkersRelationTest < ActiveSupport::TestCase
  setup do
    workers = 20.times.each.reduce([]) do |acc, index|
      acc << SolidQueue::Worker.new(queues: "*", threads: 2, polling_interval: 0)
    end
    @workers_relation = ActiveJob::WorkersRelation.new(workers:workers)
  end

  test "set limit and offset" do
    assert_equal 0, @workers_relation.offset_value

    workers = @workers_relation.offset(10).limit(20)
    assert_equal 10, workers.offset_value
    assert_equal 20, workers.limit_value
    assert_equal 10, workers.count
  end

  test "limit workers" do
    workers = @workers_relation.limit(10)
    assert_equal 10, workers.count
  end

  test "offset workers" do
    workers = @workers_relation.offset(10)
    assert_equal 10, workers.count
  end


end
