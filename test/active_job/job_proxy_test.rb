require "test_helper"

class ActiveJob::JobProxyTest < ActiveSupport::TestCase
  test "serializes and deserializes jobs respecting their original class" do
    job = DummyJob.new(123)
    job_proxy = ActiveJob::JobProxy.new(job.serialize)
    assert_instance_of DummyJob, ActiveJob::Base.deserialize(job_proxy.serialize)
  end

  test "#duration does not break if scheduled_at is not set" do
    job = DummyJob.new(123)
    job_proxy = ActiveJob::JobProxy.new(job.serialize)
    job_proxy.finished_at = job_proxy.enqueued_at + 5.seconds
    assert_equal 5.seconds, job_proxy.duration
  end
end
