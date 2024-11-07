class MissionControl::Jobs::InternalApi::NavigationController < MissionControl::Jobs::ApplicationController
  def index
    render partial: "layouts/mission_control/jobs/navigation_update", locals: { 
      section: params[:section].to_sym
    }
  end
end
