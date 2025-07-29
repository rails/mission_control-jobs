# An application containing backend jobs servers
class MissionControl::Jobs::Application
  include MissionControl::Jobs::IdentifiedByName

  attr_reader :servers, :filter_arguments

  def initialize(name:)
    super
    @servers = MissionControl::Jobs::IdentifiedElements.new
    @filter_arguments = []
  end

  def add_servers(queue_adapters_by_name)
    queue_adapters_by_name.each do |name, queue_adapter|
      adapter, cleaner = queue_adapter

      servers << MissionControl::Jobs::Server.new(name: name.to_s, queue_adapter: adapter,
        backtrace_cleaner: cleaner, application: self)
    end
  end

  def filter_arguments=(arguments)
    @filter_arguments = Array(arguments).map(&:to_s)
  end
end
