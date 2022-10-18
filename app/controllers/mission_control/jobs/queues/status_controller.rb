class MissionControl::Jobs::Queues::StatusController < MissionControl::Jobs::ApplicationController
  before_action :set_queue

  def pause
    @queue.pause

    redirect_back fallback_location: application_queues_url(@application)
  end

  def resume
    @queue.resume

    redirect_back fallback_location: application_queues_url(@application)
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:queue_id]]
    end
end
