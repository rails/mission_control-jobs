module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?
  end

  private
    def set_filters
      @job_filters = { job_class_name: params.dig(:filter, :job_class_name).presence, queue_name: params.dig(:filter, :queue_name).presence,
                       finished_at_start: date_with_time_zone(params.dig(:filter, :finished_at_start).presence), finished_at_end: date_with_time_zone(params.dig(:filter, :finished_at_end).presence) }.compact
    end

    def active_filters?
      @job_filters.any?
    end

    def date_with_time_zone(date)
      return date if date.nil?
      DateTime.parse(date).in_time_zone
    end
end
