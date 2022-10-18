module MissionControl::Jobs::QueueScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_queue
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queues[params[:queue_id]] or raise MissionControl::Jobs::Errors::ResourceNotFound, "Queue '#{params[:queue_id]}' not found"
    end
end
