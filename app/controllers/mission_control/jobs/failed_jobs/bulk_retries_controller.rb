class MissionControl::Jobs::FailedJobs::BulkRetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  def create
    jobs_to_retry_count = bulk_limited_filtered_failed_jobs.count
    bulk_limited_filtered_failed_jobs.retry_all

    redirect_to application_failed_jobs_url(@application), notice: "Retried #{jobs_to_retry_count} jobs"
  end
end
