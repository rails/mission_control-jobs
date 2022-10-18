class MissionControl::Jobs::Queues::StatusController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped

  def pause
    @queue.pause

    redirect_back fallback_location: application_queues_url(@application)
  end

  def resume
    @queue.resume

    redirect_back fallback_location: application_queues_url(@application)
  end
end
