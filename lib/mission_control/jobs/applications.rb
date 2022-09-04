# A container to register applications
class MissionControl::Jobs::Applications < MissionControl::Jobs::IdentifiedElements
  def add(name, queue_adapters_by_name = {})
    self << MissionControl::Jobs::Application.new(name: name).tap do |application|
      application.add_servers(queue_adapters_by_name)
    end
  end
end
