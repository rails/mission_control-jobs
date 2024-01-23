class MissionControl::Jobs::RetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobScoped

  def create
    @job.retry
    redirect_to application_jobs_url(@application, :failed), notice: "Retried job with id #{@job.job_id}"
  end
end
