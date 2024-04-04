require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  test "it supports queue pausing when ResquePauseHelper is defined" do
    assert ActiveJob::Base.queue_adapter.supports_queue_pausing?
  end

  test "it does not support queue pausing when ResquePauseHelper is not defined" do
    emulating_resque_pause_gem_absence do
      assert_not ActiveJob::Base.queue_adapter.supports_queue_pausing?
    end
  end

  private
    def emulating_resque_pause_gem_absence
      helper_const = Object.send(:remove_const, :ResquePauseHelper)
      yield
    ensure
      Object.const_set(:ResquePauseHelper, helper_const)
    end

    def queue_adapter
      :resque
    end

    def perform_enqueued_jobs
      @worker ||= Resque::Worker.new("*")
      @worker.work(0.0)
    end
end
