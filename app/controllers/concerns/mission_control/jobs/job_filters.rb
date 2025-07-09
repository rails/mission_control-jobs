module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?
  end

  private
    def set_filters
      @job_filters = {
        job_class_name: params.dig(:filter, :job_class_name).presence,
        queue_name: params.dig(:filter, :queue_name).presence,
        finished_at: date_range_params(:finished_at),
        enqueued_at: date_range_params(:enqueued_at),
        scheduled_at: date_range_params(:scheduled_at)
      }.compact
    end

    def active_filters?
      @job_filters.any?
    end

    def date_range_params(date_type)
      range_start, range_end = params.dig(:filter, :"#{date_type}_start"), params.dig(:filter, :"#{date_type}_end")
      if range_start || range_end
        (parse_with_time_zone(range_start)..parse_with_time_zone(range_end))
      end
    end

    def parse_with_time_zone(date)
      DateTime.parse(date).in_time_zone if date.present?
    end
end
