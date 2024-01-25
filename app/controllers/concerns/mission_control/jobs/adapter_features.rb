module MissionControl::Jobs::AdapterFeatures
  extend ActiveSupport::Concern

  included do
    helper_method :supported_job_statuses
  end

  private
    def supported_job_statuses
      MissionControl::Jobs::Current.server.queue_adapter.supported_statuses
    end
end
