class MissionControl::Jobs::Queues::StatusController < MissionControl::Jobs::ApplicationController
  before_action :set_queue

  def pause
    @queue.pause

    redirect_to queues_url
  end

  def resume
    @queue.resume

    redirect_to queues_url
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:queue_id]]
    end
end
