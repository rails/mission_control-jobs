class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  ActionController::Base::MODULES.each do |mod|
    include mod unless self < mod
  end

  layout "mission_control/jobs/application"

  # Include helpers if not already included
  helper MissionControl::Jobs::ApplicationHelper unless self < MissionControl::Jobs::ApplicationHelper
  helper Importmap::ImportmapTagsHelper unless self < Importmap::ImportmapTagsHelper

  include MissionControl::Jobs::ApplicationScoped, MissionControl::Jobs::NotFoundRedirections
  include MissionControl::Jobs::AdapterFeatures

  before_action :http_auth

  private
    def http_auth
      name = MissionControl::Jobs.http_auth_user.presence
      password = MissionControl::Jobs.http_auth_password.presence
      http_basic_authenticate_or_request_with(name:, password:) if name && password
    end

    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end
end
