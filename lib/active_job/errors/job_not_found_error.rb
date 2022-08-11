module ActiveJob
  module Errors
    class JobNotFoundError < StandardError
      def initialize(job_or_job_id)
        job_id = job_or_job_id.is_a?(ActiveJob::Base) ? job_or_job_id : job_id
        super "Job with id '#{job_id}' not found"
      end
    end
  end
end
