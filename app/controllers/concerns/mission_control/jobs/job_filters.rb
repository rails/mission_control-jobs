module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?
  end

  private
    def set_filters
      @job_filters = { job_class_name: params.dig(:filter, :job_class_name).presence, queue_name: params.dig(:filter, :queue_name).presence,
                       finished_at: date_with_time_zone(params.dig(:filter, :finished_at_start))..date_with_time_zone(params.dig(:filter, :finished_at_end)) }.compact
    end

    def active_filters?
      @job_filters.any?
    end

    # TODO: move to helpers ?
    def date_with_time_zone(date)
      if date.present?
        DateTime.parse(date).in_time_zone
      end
    end
end
