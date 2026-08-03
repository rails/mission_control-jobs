class MissionControl::Jobs::BatchesController < MissionControl::Jobs::ApplicationController
  JOB_STATUSES = %w[ pending failed in_progress blocked scheduled finished ]
  UNFINISHED_JOB_STATUSES = %i[ pending in_progress blocked scheduled ]
  BATCHES_STATUSES = %w[ finished unfinished failed ]

  before_action :ensure_supported_batches
  before_action :set_batch, only: :show

  def index
    @batches_page = MissionControl::Jobs::Page.new(batches, page: params[:page].to_i)
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@batch.jobs.with_status(jobs_status.to_sym), page: params[:page].to_i)
  end

  private
    def ensure_supported_batches
      unless batches_supported?
        redirect_to root_url, alert: "This server doesn't support batches"
      end
    end

    def set_batch
      @batch = MissionControl::Jobs::Current.server.find_batch(params[:id])
    end

    def batches
      MissionControl::Jobs::Current.server.batches(status: batches_status&.to_sym)
    end

    helper_method :batches_status, :batches_filter_param, :jobs_status

    # Default to unfinished: finished/all populations can be multi-million-row,
    # and only unfinished batches are actionable.
    def batches_status
      requested = params.fetch(:batches_status, "unfinished")
      requested.presence_in(BATCHES_STATUSES) unless requested == "all"
    end

    def batches_filter_param
      { batches_status: batches_status }.compact
    end

    def jobs_status
      if params[:jobs_status].in?(JOB_STATUSES)
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
      UNFINISHED_JOB_STATUSES.find { |status| @batch.public_send("#{status}_jobs") > 0 }&.to_s || "pending"
    end
end
