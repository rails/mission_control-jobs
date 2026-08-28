class MissionControl::Jobs::InternalApi::NavigationController < MissionControl::Jobs::ApplicationController
  include ActionView::Helpers::NumberHelper
  include MissionControl::Jobs::NavigationHelper

  def index
    @navigation_sections = navigation_sections

    render partial: "layouts/mission_control/jobs/navigation_update", locals: {
      section: params[:section].to_sym
    }
  end
end
