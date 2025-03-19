class MissionControl::Jobs::ManyRetriesController < MissionControl::Jobs::ApplicationController
  def create
    retried_jobs = params[:job_ids].map do |job_id|
      job = ActiveJob.jobs.find_by_id(job_id)
      job.retry if job&.failed?
    end.compact
    redirect_to request.referer, notice: "Retried #{retried_jobs.size} of #{params[:job_ids].size} selected jobs"
  end
end
