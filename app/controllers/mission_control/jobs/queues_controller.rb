class MissionControl::Jobs::QueuesController < MissionControl::Jobs::ApplicationController
  def index
    @queues = ActiveJob::Base.queues.values
  end
end
