class MissionControl::Jobs::Queues::PausesController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped

  def create
    @queue.pause

    redirect_back fallback_location: application_queues_url(@application)
  end

  def destroy
    @queue.resume

    redirect_back fallback_location: application_queues_url(@application)
  end
end
