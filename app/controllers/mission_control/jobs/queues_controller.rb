class MissionControl::Jobs::QueuesController < MissionControl::Jobs::ApplicationController
  before_action :set_queue, only: :show

  def index
    @queues = ActiveJob.queues.sort_by(&:name)
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@queue.jobs, page: params[:page].to_i)
  end

  private
    def set_queue
      @queue = ActiveJob.queues[params[:id]] || ActiveJob.queues.find { |q| q.id == params[:id] }
    end
end
