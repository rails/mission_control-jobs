class MissionControl::Jobs::FailedJobs::BulkRetriesController < MissionControl::Jobs::ApplicationController
  def create
    jobs_to_retry_count = ApplicationJob.jobs.failed.count
    ApplicationJob.jobs.failed.retry_all

    redirect_to failed_jobs_url, notice: "Retried #{jobs_to_retry_count} jobs"
  end
end
