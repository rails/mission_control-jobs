class MissionControl::Jobs::RetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.retry
    redirect_to application_jobs_url(@application, :failed), notice: "Retried job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      ApplicationJob.jobs.failed
    end
end
