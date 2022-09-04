class MissionControl::Jobs::ApplicationController < ActionController::Base
  layout "mission_control/jobs/application"

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end
end
