require "test_helper"

class ActiveJob::QueueAdapters::QueueAdapterTest < ActiveSupport::TestCase
  include ResqueHelper

  test "assigning a resque adapter will activate it" do
    old_redis = create_resque_redis "old"
    Resque.redis = old_redis

    new_redis = create_resque_redis "new"
    adapter = ActiveJob::QueueAdapters::ResqueAdapter.new(new_redis)

    assert_changes -> { current_resque_redis }, from: old_redis, to: new_redis do
      ActiveJob::Base.queue_adapter = adapter
    end
  end

  test "changing the current resque adapter" do
    current_adapter = ActiveJob::Base.queue_adapter
    new_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new

    assert_changes -> { ActiveJob::Base.queue_adapter }, from: current_adapter, to: new_adapter do
      ActiveJob::Base.current_queue_adapter = new_adapter
    end
  end

  test "changing current resque adapter is thread-safe" do
    2.times.collect { ActiveJob::QueueAdapters::ResqueAdapter.new }.flat_map do |new_adapter|
      20.times.collect do
        Thread.new do
          ActiveJob::Base.current_queue_adapter = new_adapter
          sleep_to_force_race_condition
          assert_equal new_adapter, ActiveJob::Base.queue_adapter
        end
      end
    end.flatten.each(&:join)
  end
end
