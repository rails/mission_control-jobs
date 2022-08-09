module MissionControl
  module Jobs
    class ApplicationController < ActionController::Base
      layout "mission_control/jobs/application"

      self.include_all_helpers = true
    end
  end
end
