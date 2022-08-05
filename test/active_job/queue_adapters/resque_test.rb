require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  private
    def queue_adapter
      :resque
    end
end
