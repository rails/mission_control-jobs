module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    # TODO: These should be moved to +ActiveJob::Core+ when upstreaming.
    attr_accessor :last_execution_error
    attr_reader :serialized_arguments
  end

  def retry
    ActiveJob.jobs.failed.retry_job(self)
  end
end
