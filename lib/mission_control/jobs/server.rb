class MissionControl::Jobs::Server
  attr_reader :name, :queue_adapter

  def initialize(name:, queue_adapter:)
    @name = name
    @queue_adapter = queue_adapter
  end

  alias to_s name

  def to_param
    name.parameterize
  end
end
