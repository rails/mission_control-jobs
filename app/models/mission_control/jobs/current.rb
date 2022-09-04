class MissionControl::Jobs::Current < ActiveSupport::CurrentAttributes
  attribute :application, :server

  def server=(server)
    super
    ActiveJob::Base.current_queue_adapter = server.queue_adapter
  end
end
