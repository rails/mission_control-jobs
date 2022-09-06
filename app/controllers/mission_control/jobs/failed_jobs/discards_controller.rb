class MissionControl::Jobs::FailedJobs::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobScoped, MissionControl::Jobs::ApplicationScoped

  def create
    @job.discard
    redirect_to application_failed_jobs_url(@application), notice: "Discarded job with id #{@job.job_id}"
  end
end
