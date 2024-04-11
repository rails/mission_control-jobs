class MissionControl::Jobs::WorkersController < MissionControl::Jobs::ApplicationController
  before_action :ensure_exposed_workers
  before_action :set_filters, only: :index

  helper_method :active_filters?, :workers_filter_param

  def index
    @workers_page = MissionControl::Jobs::Page.new(workers_relation, page: params[:page].to_i)
    @workers_count = @workers_page.total_count
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

    def workers_relation
      MissionControl::Jobs::Current.server.workers_relation.where(**@worker_filters)
    end

    def active_filters?
      @worker_filters.any?
    end

    def workers_filter_param
      if @worker_filters&.any?
        { filter: @worker_filters }
      else
        {}
      end
    end

    def set_filters
      @worker_filters = { hostname: params.dig(:filter, :hostname).presence, name: params.dig(:filter, :hostname) }.compact
    end
end
