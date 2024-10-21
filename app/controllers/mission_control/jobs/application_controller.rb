class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  layout "mission_control/jobs/application"

  include MissionControl::Jobs::ApplicationScoped, MissionControl::Jobs::NotFoundRedirections
  include MissionControl::Jobs::AdapterFeatures

  around_action :set_current_locale

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end

    def set_current_locale(&block)
      I18n.with_locale(:en, &block)
    end
end
