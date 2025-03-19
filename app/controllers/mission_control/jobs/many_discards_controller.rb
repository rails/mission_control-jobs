class MissionControl::Jobs::ManyDiscardsController < MissionControl::Jobs::ApplicationController
  def create
    discarded_jobs = params[:job_ids].map do |job_id|
      ActiveJob.jobs.find_by_id(job_id)&.discard
    end.compact
    redirect_to request.referer, notice: "Discarded #{discarded_jobs.size} of #{params[:job_ids].size} selected jobs"
  end
end
