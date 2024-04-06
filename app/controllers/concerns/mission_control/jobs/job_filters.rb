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
      finished_at_timezoned_filters
    end

    def finished_at_timezoned_filters
      @job_filters[:finished_at_start] = DateTime.parse(@job_filters[:finished_at_start]).in_time_zone if @job_filters[:finished_at_start].present?
      @job_filters[:finished_at_end] = DateTime.parse(@job_filters[:finished_at_end]).in_time_zone if @job_filters[:finished_at_end].present?
    end

    def active_filters?
      @job_filters.any?
    end
end
