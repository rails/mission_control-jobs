module MissionControl::Jobs::Server::RecurringTasks
  def recurring_tasks
    queue_adapter.recurring_tasks.collect do |task|
      MissionControl::Jobs::RecurringTask.new(queue_adapter: queue_adapter, **task)
    end
  end

  def find_recurring_task(task_id)
    if task = queue_adapter.find_recurring_task(task_id)
      MissionControl::Jobs::RecurringTask.new(queue_adapter: queue_adapter, **task)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "No recurring task found with ID #{task_id}"
    end
  end
end
