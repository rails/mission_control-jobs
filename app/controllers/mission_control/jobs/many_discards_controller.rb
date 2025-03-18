class MissionControl::Jobs::ManyDiscardsController < MissionControl::Jobs::ApplicationController
  def create
    params[:job_ids].each do |job_id|
      ActiveJob.jobs.find_by_id!(job_id).discard
    end
  end
end
