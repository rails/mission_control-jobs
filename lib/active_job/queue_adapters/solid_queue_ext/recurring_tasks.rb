module ActiveJob::QueueAdapters::SolidQueueExt::RecurringTasks
  def supports_recurring_tasks?
    true
  end

  def recurring_tasks
    tasks = recurring_tasks_from_dispatchers
    last_enqueued_at_times = recurring_task_last_enqueued_at(tasks.keys)

    recurring_tasks_from_dispatchers.collect do |task_id, task_attrs|
      recurring_task_attributes_from_solid_queue_task_attributes(task_attrs).merge \
        id: task_id,
        last_enqueued_at: last_enqueued_at_times[task_id]
    end
  end

  def find_recurring_task(task_id)
    if task_attrs = recurring_tasks_from_dispatchers[task_id]
      recurring_task_attributes_from_solid_queue_task_attributes(task_attrs).merge \
        id: task_id,
        last_enqueued_at: recurring_task_last_enqueued_at(task_id)
    end
  end

  private
    def recurring_tasks_from_dispatchers
      SolidQueue::Process.where(kind: "Dispatcher").flat_map do |process|
        process.metadata["recurring_schedule"]
      end.compact.reduce({}, &:merge)
    end

    def recurring_task_attributes_from_solid_queue_task_attributes(task_attributes)
      {
        job_class_name: task_attributes["class_name"],
        arguments: task_attributes["arguments"],
        schedule: task_attributes["schedule"]
      }
    end

    def recurring_task_last_enqueued_at(task_keys)
      times = SolidQueue::RecurringExecution.where(task_key: task_keys).group(:task_key).maximum(:run_at)
      times.one? ? times.first : times
    end
end
