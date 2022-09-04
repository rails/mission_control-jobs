class MissionControl::Jobs::FailedJobs::BulkRetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  def create
    jobs_to_retry_count = ApplicationJob.jobs.failed.count
    ApplicationJob.jobs.failed.retry_all

    redirect_to application_failed_jobs_url(@application), notice: "Retried #{jobs_to_retry_count} jobs"
  end
end
