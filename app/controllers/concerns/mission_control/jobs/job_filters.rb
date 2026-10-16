module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?, :jobs_filter_param
  end

  private
    def set_filters
      @job_filters = {
        job_class_name: params.dig(:filter, :job_class_name).to_s.strip.presence,
        queue_name: params.dig(:filter, :queue_name).to_s.strip.presence,
        finished_at: date_range_params(:finished_at),
        scheduled_at: date_range_params(:scheduled_at),
        enqueued_at: date_range_params(:enqueued_at)
      }.compact
    end

    def active_filters?
      @job_filters.any?
    end

    def jobs_filter_param
      if @job_filters&.any?
        { filter: @job_filters }
      else
        {}
      end
    end

    def date_range_params(attribute)
      raw_start = params.dig(:filter, :"#{attribute}_start")
      raw_end = params.dig(:filter, :"#{attribute}_end")
      return unless raw_start.present? || raw_end.present?

      start_time = parse_with_time_zone(raw_start)
      end_time = parse_with_time_zone(raw_end)

      # A provided endpoint that cannot be parsed must not become a nil..nil
      # (or half-nil) range — that can 500 on out-of-range dates or silently
      # apply a nonsense filter.
      return if raw_start.present? && start_time.nil?
      return if raw_end.present? && end_time.nil?

      start_time..end_time
    end

    def parse_with_time_zone(date)
      return if date.blank?

      Time.zone.parse(date)
    rescue ArgumentError, TypeError
      nil
    end
end
