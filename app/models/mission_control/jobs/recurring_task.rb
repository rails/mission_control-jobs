class MissionControl::Jobs::RecurringTask
  include ActiveModel::Model

  attr_accessor :id, :job_class_name, :command, :arguments, :schedule, :last_enqueued_at, :next_time, :queue_name, :priority

  def initialize(queue_adapter: ActiveJob::Base.queue_adapter, **kwargs)
    @queue_adapter = queue_adapter
    super(**kwargs)
  end

  def jobs
    ActiveJob::JobsRelation.new(queue_adapter: queue_adapter).where(recurring_task_id: id)
  end

  def enqueue
    queue_adapter.enqueue_recurring_task(id)
  end

  def runnable?
    queue_adapter.can_enqueue_recurring_task?(id)
  end

  private
    attr_reader :queue_adapter
end
