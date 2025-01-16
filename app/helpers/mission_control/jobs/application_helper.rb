module MissionControl::Jobs
  module ApplicationHelper
    # Explicit helper inclusion because ApplicationController inherits from the host app.
    #
    # We can't rely on +config.action_controller.include_all_helpers = true+ in the host app.
    include DatesHelper, JobsHelper, NavigationHelper, InterfaceHelper
    include MissionControl::Jobs::Engine.routes.url_helpers
  end
end
