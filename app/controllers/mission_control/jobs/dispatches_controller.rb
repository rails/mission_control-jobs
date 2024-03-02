class MissionControl::Jobs::DispatchesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.dispatch
    redirect_to application_jobs_url(@application, :blocked), notice: "Dispatched job with id #{@job.job_id}"
  end

  private
  def jobs_relation
    ApplicationJob.jobs.blocked
  end
end
