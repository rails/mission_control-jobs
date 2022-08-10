module ActiveJob::QueueAdapters::AdapterTesting::Queues
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "fetch the list of queues" do
    create_queues "queue_1", "queue_2"

    queues = ApplicationJob.queues

    assert_equal 2, queues.length
    assert_equal "queue_1", queues["queue_1"].name
    assert_equal "queue_2", queues["queue_2"].name
  end

  test "lookup queue by name" do
    create_queues "queue_1", "queue_2"

    assert_equal "queue_1", ApplicationJob.queues[:queue_1].name
    assert_equal "queue_1", ApplicationJob.queues["queue_1"].name
    assert_nil ApplicationJob.queues[:queue_3]
  end

  test "pause and resume queues" do
    create_queues "queue_1", "queue_2"

    queue = ApplicationJob.queues[:queue_1]

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

    queue = ApplicationJob.queues[:queue_1]
    assert_equal 3, queue.size
    assert_equal 3, queue.length
  end

  test "queue sizes for multiple queues" do
    3.times { DynamicQueueJob("queue_1").perform_later }
    5.times { DynamicQueueJob("queue_2").perform_later }

    assert_equal 3, ApplicationJob.queues[:queue_1].size
    assert_equal 5, ApplicationJob.queues[:queue_2].size
  end

  test "clear a queue" do
    DynamicQueueJob("queue_1").perform_later
    queue = ApplicationJob.queues[:queue_1]
    assert queue

    queue.clear
    queue = ApplicationJob.queues[:queue_1]
    assert_not queue
  end

  test "check if a queue is empty" do
    3.times { DynamicQueueJob("queue_1").perform_later }
    queue = ApplicationJob.queues[:queue_1]

    assert_not queue.empty?
  end

  test "fetch the jobs in a queue" do
    DummyJob.queue_as :queue_1
    3.times { DummyJob.perform_later }
    DummyJob.queue_as :queue_2
    5.times { DummyJob.perform_later }

    assert_equal 3, ApplicationJob.queues[:queue_1].jobs.to_a.length
    assert_equal 5, ApplicationJob.queues[:queue_2].jobs.to_a.length
  end
end
