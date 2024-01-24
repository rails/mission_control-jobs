module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters
  end

  private
    def set_filters
      @job_filters = { job_class_name: params.dig(:filter, :job_class_name).presence, queue_name: params.dig(:filter, :queue_name).presence }.compact
    end
end
