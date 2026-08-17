class MissionControl::Jobs::DashboardsController < MissionControl::Jobs::ApplicationController
  def show
    @dashboard = MissionControl::Jobs::Dashboard.new(statuses: supported_job_statuses)
    @snapshot = @dashboard.snapshot

    respond_to do |format|
      format.html
      format.json do
        expires_now
        render json: @snapshot
      end
    end
  end
end
