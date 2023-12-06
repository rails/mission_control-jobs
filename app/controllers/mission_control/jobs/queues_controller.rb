class MissionControl::Jobs::QueuesController < MissionControl::Jobs::ApplicationController
  before_action :set_queue

  def index
    @queues = filtered_queues.sort_by(&:name)
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@queue.jobs, page: params[:page].to_i)
  end

  private
    def set_queue
      @queue = ApplicationJob.queues[params[:id]]
    end

    def filtered_queues
      if prefix = ApplicationJob.queue_name_prefix
        ApplicationJob.queues.select { |queue| queue.name.start_with?(prefix) }
      else
        ApplicationJob.queues
      end
    end
end
