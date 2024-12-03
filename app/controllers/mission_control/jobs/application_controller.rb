class MissionControl::Jobs::ApplicationController < MissionControl::Jobs.base_controller_class.constantize
  ActionController::Base::MODULES.each do |mod|
    include mod unless self < mod
  end

  layout "mission_control/jobs/application"

  # Include helpers if not already included
  helper MissionControl::Jobs::ApplicationHelper unless self < MissionControl::Jobs::ApplicationHelper
  helper Importmap::ImportmapTagsHelper unless self < Importmap::ImportmapTagsHelper

  include MissionControl::Jobs::BasicAuthentication
  include MissionControl::Jobs::ApplicationScoped, MissionControl::Jobs::NotFoundRedirections
  include MissionControl::Jobs::AdapterFeatures

  around_action :set_current_locale

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end

    def set_current_locale(&block)
      @previous_config = I18n.config
      I18n.config = MissionControl::Jobs::I18nConfig.new
      I18n.with_locale(:en, &block)
    ensure
      I18n.config = @previous_config
      @previous_config = nil
    end
end
