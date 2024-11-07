class MissionControl::Jobs::DispatchesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.dispatch
    redirect_to redirect_location
  end

  private
    def jobs_relation
      ActiveJob.jobs
    end

    def redirect_location
      status = @job.status.presence_in(supported_job_statuses) || :blocked
      application_jobs_url(@application, status)
    end
end
