class MissionControl::Jobs::ManyDiscardsController < MissionControl::Jobs::ApplicationController
  def create
    discarded_jobs = job_ids.map do |job_id|
      job = ActiveJob.jobs.find_by_id(job_id)
      job.discard if job&.failed?
    end.compact
    redirect_to request.referer, notice: "Discarded #{discarded_jobs.size} of #{job_ids.size} selected jobs"
  end

  private

  def job_ids
    params[:job_ids].reject(&:blank?)
  end
end
