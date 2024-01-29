class MissionControl::Jobs::Worker
  include ActiveModel::Model

  attr_accessor :id, :name, :hostname, :last_heartbeat_at, :configuration, :raw_data

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter, **kwargs)
    @queue_adapter = queue_adapter
    super(**kwargs)
  end

  def jobs
    @jobs ||= ActiveJob::JobsRelation.new(queue_adapter: queue_adapter).in_progress.where(worker_id: id)
  end

  private
    attr_reader :queue_adapter
end
