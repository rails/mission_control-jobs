module ActiveJob::QueueAdapters::SolidQueueExt::RecurringTasks
  def supports_recurring_tasks?
    true
  end

  def recurring_tasks
    recurring_tasks_from_dispatchers.collect do |task_id, task_attrs|
      { id: task_id }.merge recurring_task_attributes_from_solid_queue_task_attributes(task_attrs)
    end
  end

  def find_recurring_task(recurring_task_id)
    if task_attrs = recurring_tasks_from_dispatchers[recurring_task_id]
      { id: recurring_task_id }.merge recurring_task_attributes_from_solid_queue_task_attributes(task_attrs)
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
end
