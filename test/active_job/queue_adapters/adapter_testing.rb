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

    queue.resume
    assert queue.active?
    assert_not queue.paused?
  end

  private
    # Template method to override in child classes. It returns the
    # name of the adapter to test.
    #
    # E.g: +:resque+, +:sidekiq+
    def queue_adapter
      raise NotImplementedError
    end
end
