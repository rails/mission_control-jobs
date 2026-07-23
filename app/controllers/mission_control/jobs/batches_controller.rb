class MissionControl::Jobs::BatchesController < MissionControl::Jobs::ApplicationController
  before_action :ensure_supported_batches
  before_action :set_batch, only: :show

  helper_method :jobs_status

  def index
    @batches = MissionControl::Jobs::Current.server.batches
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@batch.jobs.with_status(jobs_status.to_sym), page: params[:page].to_i)
  end

  private
    JOB_STATUSES = %w[ pending failed finished ]

    def ensure_supported_batches
      unless batches_supported?
        redirect_to root_url, alert: "This server doesn't support batches"
      end
    end

    def set_batch
      @batch = MissionControl::Jobs::Current.server.find_batch(params[:id])
    end

    def jobs_status
      @jobs_status ||= if params[:jobs_status].in?(JOB_STATUSES)
        params[:jobs_status]
      elsif @batch.failed?
        "failed"
      elsif @batch.finished?
        "finished"
      else
        "pending"
      end
    end
end
