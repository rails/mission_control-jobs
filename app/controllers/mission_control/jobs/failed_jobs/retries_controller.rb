class MissionControl::Jobs::FailedJobs::RetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped, MissionControl::Jobs::FailedJobScoped

  def create
    @job.retry
    redirect_to application_failed_jobs_url(@application), notice: "Retried job with id #{@job.job_id}"
  end
end
