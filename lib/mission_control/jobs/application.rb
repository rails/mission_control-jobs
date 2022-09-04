# An application containing backend jobs servers
class MissionControl::Jobs::Application
  attr_reader :name, :servers

  def initialize(name:)
    @name = name
    @servers = []
  end

  def add_servers(queue_adapters_by_name)
    queue_adapters_by_name.each do |name, queue_adapter|
      servers << MissionControl::Jobs::Server.new(name: name.to_s, queue_adapter: queue_adapter)
    end
  end

  def find_server(name)
    servers.find { |server| server.name == name }
  end

  alias to_s name

  def to_param
    name.parameterize
  end
end
