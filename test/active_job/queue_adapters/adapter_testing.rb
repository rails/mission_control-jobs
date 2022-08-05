module ActiveJob::QueueAdapters::AdapterTesting
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  included do
    setup do
      ApplicationJob.queue_adapter = queue_adapter
    end
  end

  test "fetch the list of queues" do
    create_queues "queue_1", "queue_2"

    queues = ApplicationJob.queues

    assert_equal 2, queues.length
    assert_equal "queue_1", queues[0].name
    assert_equal "queue_2", queues[1].name
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

    queue.resume
    assert queue.active?
    assert_not queue.paused?
  end

  test "queue size" do
    3.times { DynamicQueueJob("queue_1").perform_later }

    queue = ApplicationJob.queue("queue_1")
    assert_equal 3, queue.size
    assert_equal 3, queue.length
  end

  test "queue sizes for multiple queues" do
    3.times { DynamicQueueJob("queue_1").perform_later }
    5.times { DynamicQueueJob("queue_2").perform_later }

    assert_equal 3, ApplicationJob.queue("queue_1").size
    assert_equal 5, ApplicationJob.queue("queue_2").size
  end

  test "clear a queue" do
    DynamicQueueJob("queue_1").perform_later
    queue = ApplicationJob.queue("queue_1")
    assert queue

    queue.clear
    queue = ApplicationJob.queue("queue_1")
    assert_not queue
  end

  test "check if a queue is empty" do
    3.times { DynamicQueueJob("queue_1").perform_later }
    queue = ApplicationJob.queue("queue_1")

    assert_not queue.empty?
  end

  private
    # Template method to override with the adapter to test.
    #
    # E.g: +:resque+, +:sidekiq+
    def queue_adapter
      raise NotImplementedError
    end
end
