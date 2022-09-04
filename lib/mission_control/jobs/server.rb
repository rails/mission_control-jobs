class MissionControl::Jobs::Server
  attr_reader :name, :queue_adapter

  def initialize(name:, queue_adapter:)
    @name = name.to_s
    @queue_adapter = queue_adapter
  end

  alias to_s name

  def activate
    ActiveJob::Base.current_queue_adapter = queue_adapter
  end

  def to_param
    name.parameterize
  end
end
