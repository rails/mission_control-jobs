module MissionControl::Jobs::FailedJobsBulkOperations
  extend ActiveSupport::Concern

  MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS = 3000

  included do
    include MissionControl::Jobs::JobFilters
  end

  private
    # We set a hard limit to prevent problems with the data store (for example, overloading Redis
    # or causing replication lag in MySQL). This should be enough for most scenarios. For
    # cases where we need to retry a huge sets of jobs, we offer a runbook that uses the API.
    def bulk_limited_filtered_failed_jobs
      ActiveJob::Base.jobs.failed.where(**@job_filters).limit(MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS)
    end
end
