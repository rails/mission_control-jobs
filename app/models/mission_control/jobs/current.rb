class MissionControl::Jobs::Current < ActiveSupport::CurrentAttributes
  attribute :application, :server

  def server=(server)
    super
    Rails.logger.info "*" * 100
    Rails.logger.info server.queue_adapter.inspect
    ActiveJob::Base.current_queue_adapter = server.queue_adapter
  end
end
