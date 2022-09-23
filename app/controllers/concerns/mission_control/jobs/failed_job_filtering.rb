module MissionControl::Jobs::FailedJobFiltering
  extend ActiveSupport::Concern

  MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS = 3000

  included do
    before_action :set_job_class_filter
  end

  private
    def set_job_class_filter
      @job_class_filter = params.dig(:filter, :job_class)
    end

    def filtered_failed_jobs
      ApplicationJob.jobs.failed.where(job_class: @job_class_filter)
    end

    # We set a hard limit to prevent overloading redis. This should be enough for most scenarios. For
    # cases where we need to retry a huge sets of jobs, we offer a runbook that uses the new API.
    def bulk_limited_filtered_failed_jobs
      filtered_failed_jobs.limit(MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS)
    end
end
