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

  around_action :set_current_locale

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end

    def set_current_locale(&block)
      I18n.with_locale(I18n.available_locales.sort.find { |locale| locale.start_with?("en") } || I18n.default_locale, &block)
    end
end
