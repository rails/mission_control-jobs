class MissionControl::Jobs::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.discard
    redirect_to application_jobs_url(@application, :failed), notice: "Discarded job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      ActiveJob.jobs.failed
    end
end
