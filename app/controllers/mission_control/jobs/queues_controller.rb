class MissionControl::Jobs::QueuesController < MissionControl::Jobs::ApplicationController
  before_action :set_queue

  def index
    @queues = ActiveJob::Base.queues.values
  end

  def show
    @jobs = @queue.jobs
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:id]]
    end
end
