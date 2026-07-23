class MissionControl::Jobs::BatchesController < MissionControl::Jobs::ApplicationController
  before_action :ensure_supported_batches
  before_action :set_batch, only: :show

  def index
    @batches = MissionControl::Jobs::Current.server.batches
  end

  def show
    status = @batch.finished? ? :finished : :pending
    @jobs_status = status
    @jobs_page = MissionControl::Jobs::Page.new(@batch.jobs.with_status(status), page: params[:page].to_i)
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
end
