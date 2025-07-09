class MissionControl::Jobs::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.discard
    respond_to do |format|
      format.html { redirect_to redirect_location, notice: "Discarded job with id #{@job.job_id}" }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("job_#{@job.job_id}") }
    end
  end

  private
    def jobs_relation
      ActiveJob.jobs
    end

    def redirect_location
      status = @job.status.presence_in(supported_job_statuses) || :failed
      application_jobs_url(@application, status)
    end
end
