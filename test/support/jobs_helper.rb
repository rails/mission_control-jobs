module JobsHelper
  extend ActiveSupport::Concern

  def assert_job_proxy(expected_class, job)
    assert_instance_of ActiveJob::JobProxy, job
    assert_equal expected_class.to_s, job.class_name
  end
end
