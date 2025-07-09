require "test_helper"

class ActiveJob::QueueTest < ActiveSupport::TestCase
  test "to_param returns parameterized queue name" do
    queue = ActiveJob::Queue.new("MixedCaseQueue")
    assert_equal "mixedcasequeue", queue.to_param
  end

  test "to_param handles queue names with special characters" do
    queue = ActiveJob::Queue.new("My-Queue_With.Special@Chars!")
    assert_equal "my-queue_with-special-chars", queue.to_param
  end

  test "to_param handles queue names with spaces" do
    queue = ActiveJob::Queue.new("My Queue With Spaces")
    assert_equal "my-queue-with-spaces", queue.to_param
  end

  test "to_param handles queue names with underscores" do
    queue = ActiveJob::Queue.new("my_queue_with_underscores")
    assert_equal "my_queue_with_underscores", queue.to_param
  end

  test "to_param handles queue names with numbers" do
    queue = ActiveJob::Queue.new("Queue123With456Numbers")
    assert_equal "queue123with456numbers", queue.to_param
  end

  test "id is an alias for to_param" do
    queue = ActiveJob::Queue.new("MixedCaseQueue")
    assert_equal queue.to_param, queue.id
  end

  test "queue lookup by id works correctly" do
    # Create a queue with a mixed case name
    queue = ActiveJob::Queue.new("MixedCaseQueue")
    queues = ActiveJob::Queues.new([queue])
    
    # Should find the queue by its parameterized id
    assert_equal queue, queues.find { |q| q.id == "mixedcasequeue" }
    
    # Should find the queue by its original name
    assert_equal queue, queues["MixedCaseQueue"]
  end
end 