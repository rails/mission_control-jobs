module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?
  end

  private
    def set_filters
      @job_filters = { job_class_name: params.dig(:filter, :job_class_name).presence,
                       queue_name: params.dig(:filter, :queue_name).presence,
                       scheduled_at: [params.dig(:filter, :scheduled_at_start).presence, params.dig(:filter, :scheduled_at_end).presence].compact.presence
                     }.compact
    end

    def active_filters?
      @job_filters.any?
    end
end
