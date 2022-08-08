require "test_helper"

class ActiveJob::JobsRelationTest < ActiveSupport::TestCase
  setup do
    @jobs = ActiveJob::JobsRelation.new
  end

  test "pass job class names" do
    assert_nil @jobs.job_class_names
    assert [ "SomeJob" ], @jobs.where(job_class: "SomeJob").job_class_names
    assert [ "SomeJob1", "SomeJob2" ], @jobs.where(job_class: [ "SomeJob1", "SomeJob2" ])
  end

  test "set filter by failed flag" do
    assert_not @jobs.only_failed?
    assert @jobs.failed.only_failed?
  end

  test "set from and to" do
    assert_nil @jobs.from_index
    assert_nil @jobs.to_index

    jobs = @jobs.from(10).to(20)
    assert_equal 10, jobs.from_index
    assert_equal 20, jobs.to_index
  end
end
