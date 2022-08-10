require "test_helper"

class ActiveJob::JobProxyTest < ActiveSupport::TestCase
  test "serializes and deserializes jobs respecting their original class" do
    job = DummyJob.new(123)
    job_proxy = ActiveJob::JobProxy.new(job.serialize)
    assert_instance_of DummyJob, ActiveJob::Base.deserialize(job_proxy.serialize)
  end
end
