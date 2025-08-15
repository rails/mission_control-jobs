require "test_helper"

class ActiveJob::JobsRelationMemoryTest < ActiveSupport::TestCase
  setup do
    @jobs = ActiveJob::JobsRelation.new
  end

  test "does not cache jobs when iterating with each" do
    # Stub adapter calls
    ActiveJob::Base.queue_adapter.expects(:fetch_jobs).twice.returns([ :job_1, :job_2 ], [])
    ActiveJob::Base.queue_adapter.expects(:supports_job_filter?).at_least_once.returns(true)

    jobs = @jobs.where(queue_name: "my_queue")

    collected = []
    jobs.each { |job| collected << job }
    assert_equal [ :job_1, :job_2 ], collected

    # Ensure the internal loaded_jobs cache is still nil to confirm no caching happened
    assert_nil jobs.instance_variable_get(:@loaded_jobs)
  end
end
