class MissionControl::Jobs::FailedJobs::RetriesController < MissionControl::Jobs::ApplicationController
  before_action :set_job

  def create
    @job.retry

    redirect_to failed_jobs_url
  end

  private
    def set_job
      @job = ActiveJob.jobs.failed.find_by_id!(params[:failed_job_id])
    end
end
