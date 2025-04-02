class MissionControl::Jobs::ManyRetriesController < MissionControl::Jobs::ApplicationController
  def create
    retried_jobs = job_ids.map do |job_id|
      job = ActiveJob.jobs.find_by_id(job_id)
      job.retry if job&.failed?
    end.compact
    redirect_to request.referer, notice: "Retried #{retried_jobs.size} of #{job_ids.size} selected jobs"
  end

  private

  def job_ids
    params[:job_ids].reject(&:blank?)
  end
end
