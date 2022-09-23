class MissionControl::Jobs::Server
  include MissionControl::Jobs::IdentifiedByName, Serializable

  attr_reader :name, :queue_adapter, :application

  def initialize(name:, queue_adapter:, application:)
    super(name: name)
    @queue_adapter = queue_adapter
    @application = application
  end

  def activating(&block)
    previous_adapter = ActiveJob::Base.current_queue_adapter
    ActiveJob::Base.current_queue_adapter = queue_adapter
    queue_adapter.activating(&block)
  ensure
    ActiveJob::Base.current_queue_adapter = previous_adapter
  end
end
