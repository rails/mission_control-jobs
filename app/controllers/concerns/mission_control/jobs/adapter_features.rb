module MissionControl::Jobs::AdapterFeatures
  extend ActiveSupport::Concern

  included do
    helper_method :supported_job_statuses, :queue_pausing_supported?, :workers_exposed?, :recurring_tasks_supported?
  end

  private
    def supported_job_statuses
      MissionControl::Jobs::Current.server.queue_adapter.supported_job_statuses & ActiveJob::JobsRelation::STATUSES
    end

    def queue_pausing_supported?
      MissionControl::Jobs::Current.server.queue_adapter.supports_queue_pausing?
    end

    def workers_exposed?
      MissionControl::Jobs::Current.server.queue_adapter.exposes_workers?
    end

    def recurring_tasks_supported?
      MissionControl::Jobs::Current.server.queue_adapter.supports_recurring_tasks?
    end
end
