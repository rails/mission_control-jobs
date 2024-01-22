class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  layout "mission_control/jobs/application"

  include MissionControl::Jobs::ApplicationScoped

  rescue_from(ActiveJob::Errors::JobNotFoundError) do |error|
    redirect_to root_path, alert: error.message
  end

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end
end
