class MissionControl::Jobs::Queues::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped

  def create
    @queue.clear

    redirect_to application_queues_url(@application)
  end
end
