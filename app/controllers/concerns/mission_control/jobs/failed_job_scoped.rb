module MissionControl::Jobs::FailedJobScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_job
  end

  private
    def set_job
      @job = ActiveJob.jobs.failed.find_by_id!(params[:failed_job_id])
    end
end
