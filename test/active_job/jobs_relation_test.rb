require "test_helper"

class ActiveJob::JobsRelationTest < ActiveSupport::TestCase
  setup do
    @jobs = ActiveJob::JobsRelation.new
  end

  test "pass job class names" do
    assert_nil @jobs.job_class_name
    assert "SomeJob", @jobs.where(job_class: "SomeJob").job_class_name
  end

  test "filter by pending status" do
    assert @jobs.pending?
    assert @jobs.pending.pending?
    assert_not @jobs.failed.pending?
  end

  test "filter by failed status" do
    assert_not @jobs.failed?
    assert @jobs.failed.failed?
  end

  test "set limit and offset" do
    assert_equal 0, @jobs.offset_value

    jobs = @jobs.offset(10).limit(20)
    assert_equal 10, jobs.offset_value
    assert_equal 20, jobs.limit_value
  end

  test "set job class and queue" do
    jobs = @jobs.where(job_class: "MyJob")
    assert_equal "MyJob", jobs.job_class_name

    # Supports concatenation without overriding exising properties
    jobs = jobs.where(queue: "my_queue")
    assert_equal "my_queue", jobs.queue_name
    assert_equal "MyJob", jobs.job_class_name
  end
end
