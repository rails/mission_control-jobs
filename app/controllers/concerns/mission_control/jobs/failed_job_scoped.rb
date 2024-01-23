module MissionControl::Jobs::FailedJobScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_job
  end

  private
    def set_job
      @job = ActiveJob.jobs.failed.find_by_id!(params[:job_id])
    end
end
