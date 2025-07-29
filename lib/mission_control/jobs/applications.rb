# A container to register applications
class MissionControl::Jobs::Applications < MissionControl::Jobs::IdentifiedElements
  def add(name, queue_adapters_by_name = {}, filter_arguments = [])
    self << MissionControl::Jobs::Application.new(name: name).tap do |application|
      application.add_servers(queue_adapters_by_name)
      application.filter_arguments = filter_arguments.presence || MissionControl::Jobs.filter_arguments
    end
  end
end
