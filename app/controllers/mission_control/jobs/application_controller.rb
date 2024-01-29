class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  layout "mission_control/jobs/application"

  include MissionControl::Jobs::ApplicationScoped, MissionControl::Jobs::NotFoundRedirections
  include MissionControl::Jobs::AdapterFeatures

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end
end
