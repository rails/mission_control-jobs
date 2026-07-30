class MissionControl::Jobs::BatchesController < MissionControl::Jobs::ApplicationController
  before_action :ensure_supported_batches
  before_action :set_batch, only: :show

  helper_method :jobs_status

  def index
    @batches_page = MissionControl::Jobs::Page.new(MissionControl::Jobs::Current.server.batches, page: params[:page].to_i)
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@batch.jobs.with_status(jobs_status.to_sym), page: params[:page].to_i)
  end

  private
    JOB_STATUSES = %w[ pending failed in_progress blocked scheduled finished ]
    UNFINISHED_JOB_STATUSES = %i[ pending in_progress blocked scheduled ]

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
        default_unfinished_jobs_status
      end
    end

    def default_unfinished_jobs_status
      UNFINISHED_JOB_STATUSES.find { |status| @batch.public_send("#{status}_jobs").positive? }&.to_s || "pending"
    end
end
