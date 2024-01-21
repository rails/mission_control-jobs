class MissionControl::Jobs::JobsController < MissionControl::Jobs::ApplicationController
  before_action :set_job

  def show
  end

  private
    def set_job
      @job = jobs_relation.find_by_id!(params[:id])
    end

    def jobs_relation
      ApplicationJob.jobs
    end
end
