require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  setup do
    ApplicationJob.queue_adapter = :resque
  end

  test "fetch the list of queues" do
    create_queues "queue_1", "queue_2"

    assert_queues "queue_1", "queue_2"
  end

  test "find queue by name" do
    create_queues "queue_1", "queue_2"

    assert_equal "queue_1", ApplicationJob.find_queue("queue_1").name
    assert_nil ApplicationJob.find_queue("queue_3")
  end
end
