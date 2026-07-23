class MissionControl::Jobs::Batch
  include ActiveModel::Model

  attr_accessor :id, :description, :status, :total_jobs, :completed_jobs, :failed_jobs,
    :pending_jobs, :progress_percentage, :metadata, :enqueued_at, :finished_at

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter, **kwargs)
    @queue_adapter = queue_adapter
    super(**kwargs)
  end

  def jobs
    ActiveJob::JobsRelation.new(queue_adapter: queue_adapter).where(batch_id: id)
  end

  def finished?
    finished_at.present?
  end

  def failed?
    status == :failed
  end

  private
    attr_reader :queue_adapter
end
