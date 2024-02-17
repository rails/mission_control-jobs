class MissionControl::Jobs::QueuesController < MissionControl::Jobs::ApplicationController
  before_action :set_queue, only: :show

  def index
    @queues = filtered_queues.sort_by(&:name)
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@queue.jobs, page: params[:page].to_i)
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:id]]
    end

    def filtered_queues
      if prefix = ActiveJob::Base.queue_name_prefix
        ActiveJob::Base.queues.select { |queue| queue.name.start_with?(prefix) }
      else
        ActiveJob::Base.queues
      end
    end
end
