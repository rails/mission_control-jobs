class MissionControl::Jobs::ApplicationController < ActionController::Base
  layout "mission_control/jobs/application"

  before_action :dummy

  private
    def default_url_options
      { server_id: MissionControl::Jobs::Current.server }
    end

    def dummy
      ActiveJob::Base.current_queue_adapter = MissionControl::Jobs.applications.first.servers.first.queue_adapter
    end
end
