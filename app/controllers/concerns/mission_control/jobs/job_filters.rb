module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters
  end

  private
    def set_filters
      @job_filters = { job_class: params.dig(:filter, :job_class).presence, queue: params.dig(:filter, :queue).presence }.compact
    end
end
