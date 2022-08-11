class MissionControl::Jobs::FailedJobs::BulkRetriesController < MissionControl::Jobs::ApplicationController
  def create
    ApplicationJob.jobs.failed.retry_all

    redirect_to failed_jobs_url
  end
end
