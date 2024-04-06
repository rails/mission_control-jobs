module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?
  end

  private
    def set_filters
      @job_filters = { job_class_name: params.dig(:filter, :job_class_name).presence, queue_name: params.dig(:filter, :queue_name).presence,
                       finished_at_start: params.dig(:filter, :finished_at_start).presence, finished_at_end: params.dig(:filter, :finished_at_end) }.compact
    end
    end

    def active_filters?
      @job_filters.any?
    end
end
