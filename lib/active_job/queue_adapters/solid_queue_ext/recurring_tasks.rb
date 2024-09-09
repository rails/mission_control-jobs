module ActiveJob::QueueAdapters::SolidQueueExt::RecurringTasks
  def supports_recurring_tasks?
    true
  end

  def recurring_tasks
    tasks = SolidQueue::RecurringTask.all
    last_enqueued_at_times = recurring_task_last_enqueued_at(tasks.map(&:key))

    tasks.collect do |task|
      recurring_task_attributes_from_solid_queue_recurring_task(task).merge \
        last_enqueued_at: last_enqueued_at_times[task.key]
    end
  end

  def find_recurring_task(task_id)
    if task = SolidQueue::RecurringTask.find_by(key: task_id)
      recurring_task_attributes_from_solid_queue_recurring_task(task).merge \
        last_enqueued_at: recurring_task_last_enqueued_at(task.key).values&.first
    end
  end

  private
    def recurring_task_attributes_from_solid_queue_recurring_task(task)
      {
        id: task.key,
        job_class_name: task.class_name,
        command: task.command,
        arguments: task.arguments,
        schedule: task.schedule,
        queue_name: task.queue_name,
        priority: task.priority
      }
    end

    def recurring_task_last_enqueued_at(task_keys)
      SolidQueue::RecurringExecution.where(task_key: task_keys).group(:task_key).maximum(:run_at)
    end
end
