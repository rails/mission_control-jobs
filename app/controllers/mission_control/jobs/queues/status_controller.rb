class MissionControl::Jobs::Queues::StatusController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  before_action :set_queue

  def pause
    @queue.pause

    redirect_to application_queues_url(@application)
  end

  def resume
    @queue.resume

    redirect_to application_queues_url(@application)
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:queue_id]]
    end
end
