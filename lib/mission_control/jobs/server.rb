class MissionControl::Jobs::Server
  attr_reader :name, :queue_adapter

  def initialize(name:, queue_adapter:)
    @name = name
    @queue_adapter = queue_adapter
  end
end
