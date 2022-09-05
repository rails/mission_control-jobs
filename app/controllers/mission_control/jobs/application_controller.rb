class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  layout "mission_control/jobs/application"

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end
end
