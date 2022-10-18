class MissionControl::Jobs::Queues::JobsController < MissionControl::Jobs::ApplicationController
  before_action :set_queue
  before_action :set_job, only: %i[ show ]

  def show
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:queue_id]] or raise MissionControl::Jobs::Errors::ResourceNotFound, "Queue '#{params[:queue_id]}' not found"
    end

    def set_job
      @job = @queue.jobs.pending.find_by_id!(params[:id])
    end
end
