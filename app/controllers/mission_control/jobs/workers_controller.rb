class MissionControl::Jobs::WorkersController < MissionControl::Jobs::ApplicationController
  before_action :ensure_exposed_workers

  def index
    @workers = MissionControl::Jobs::Current.server.workers.sort_by { |worker| -worker.jobs.count }
  end

  def show
    @worker = MissionControl::Jobs::Current.server.find_worker(params[:id])
  end

  private
    def ensure_exposed_workers
      unless workers_exposed?
        redirect_to root_url, alert: "This server doesn't expose workers"
      end
    end
end
