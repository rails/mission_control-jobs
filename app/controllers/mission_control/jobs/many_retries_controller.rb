class MissionControl::Jobs::ManyRetriesController < MissionControl::Jobs::ApplicationController
  # include MissionControl::Jobs::FailedJobsBulkOperations

  def create
    params[:job_ids].each do |job_id|
      ActiveJob.jobs.find_by_id!(job_id).retry
    end
  end
end
