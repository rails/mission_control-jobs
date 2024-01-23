module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS = 3000

  included do
    before_action :set_filters
  end

  private
    def set_filters
      @job_filters = { job_class: params.dig(:filter, :job_class).presence, queue: params.dig(:filter, :queue).presence }.compact
    end

    def filtered_failed_jobs
      ApplicationJob.jobs.failed.where(**@job_filters)
    end

    # We set a hard limit to prevent problems with the data store (for example, overloading Redis
    # or causing replication lag in MySQL). This should be enough for most scenarios. For
    # cases where we need to retry a huge sets of jobs, we offer a runbook that uses the API.
    def bulk_limited_filtered_failed_jobs
      filtered_failed_jobs.limit(MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS)
    end
end
