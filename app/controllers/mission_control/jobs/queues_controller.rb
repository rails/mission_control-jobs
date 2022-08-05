class MissionControl::Jobs::QueuesController < ApplicationController
  def index
    @queues = ActiveJob::Base.queues.values
  end
end
