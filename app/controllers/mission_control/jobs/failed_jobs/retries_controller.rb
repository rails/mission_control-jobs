class MissionControl::Jobs::FailedJobs::RetriesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  before_action :set_job

  def create
    @job.retry

    redirect_to application_failed_jobs_url(@application), notice: "Retried job with id #{@job.job_id}"
  end

  private
    def set_job
      @job = ActiveJob.jobs.failed.find_by_id!(params[:failed_job_id])
    end
end
