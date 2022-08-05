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

    assert_equal "queue_1", ApplicationJob.queue("queue_1").name
    assert_nil ApplicationJob.queue("queue_3")
  end

  test "pause and resume queues" do
    create_queues "queue_1", "queue_2"

    queue = ApplicationJob.queue("queue_1")

    assert queue.active?
    assert_not queue.paused?

    queue.pause
    assert_not queue.active?
    assert queue.paused?
  end
end
