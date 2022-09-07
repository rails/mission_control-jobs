require "test_helper"

class ActiveJob::QueueAdapters::QueueAdapterTest < ActiveSupport::TestCase
  include ResqueHelper

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
