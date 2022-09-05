# An application containing backend jobs servers
class MissionControl::Jobs::Application
  include MissionControl::Jobs::IdentifiedByName

  attr_reader :servers

  def initialize(name:)
    super
    @servers = MissionControl::Jobs::IdentifiedElements.new
  end

  def add_servers(queue_adapters_by_name)
    queue_adapters_by_name.each do |name, queue_adapter|
      servers << MissionControl::Jobs::Server.new(name: name.to_s, queue_adapter: queue_adapter)
    end
  end
end
