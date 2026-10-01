class MissionControl::Jobs::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.discard
    redirect_to redirect_location, notice: "Discarded job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      ActiveJob.jobs
    end

    def redirect_location
      if @job.pending?
        application_queue_path(@application, @job.queue_name)
      else
        status = @job.status.presence_in(supported_job_statuses) || :failed
        application_jobs_url(@application, status, **jobs_filter_param)
      end
    end
end
