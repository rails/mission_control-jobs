require "active_job/queue_adapter"

class MissionControl::Jobs::Server
  include MissionControl::Jobs::IdentifiedByName
  include Serializable, RecurringTasks, Workers

  attr_reader :name, :queue_adapter, :application, :backtrace_cleaner

  def initialize(name:, queue_adapter:, application:, backtrace_cleaner: nil)
    super(name: name)
    @queue_adapter = queue_adapter
    @application = application
    @backtrace_cleaner = backtrace_cleaner || MissionControl::Jobs.backtrace_cleaner
  end

  def activating(&block)
    previous_adapter = ActiveJob::Base.current_queue_adapter
    ActiveJob::Base.current_queue_adapter = queue_adapter
    queue_adapter.activating(&block)
  ensure
    ActiveJob::Base.current_queue_adapter = previous_adapter
  end

  def queue_adapter_name
    ActiveJob.adapter_name(queue_adapter).underscore.to_sym
  end
end
