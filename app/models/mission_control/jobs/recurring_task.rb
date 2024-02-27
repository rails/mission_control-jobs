class MissionControl::Jobs::RecurringTask
  include ActiveModel::Model

  attr_accessor :id, :job_class_name, :arguments, :schedule

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter, **kwargs)
    @queue_adapter = queue_adapter
    super(**kwargs)
  end

  def last_enqueued_at
    jobs.first&.enqueued_at
  end

  def jobs
    ActiveJob::JobsRelation.new(queue_adapter: queue_adapter).where(recurring_task_id: id)
  end

  private
    attr_reader :queue_adapter
end
