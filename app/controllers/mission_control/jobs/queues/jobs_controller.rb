class MissionControl::Jobs::Queues::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped

  before_action :set_job, only: %i[ show ]

  def show
  end

  private
    def set_job
      @job = @queue.jobs.pending.find_by_id!(params[:id])
    end
end
