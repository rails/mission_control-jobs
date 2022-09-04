class MissionControl::Jobs::Current < ActiveSupport::CurrentAttributes
  attribute :application, :server

  def server=(server)
    super
    server.activate
  end
end
