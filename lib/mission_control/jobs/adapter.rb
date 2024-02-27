module MissionControl::Jobs::Adapter
  def activating(&block)
    block.call
  end

  def supports_job_status?(status)
    supported_job_statuses.include?(status)
  end

  def supported_job_statuses
    # All adapters need to support these at a minimum
    [ :pending, :failed ]
  end

  def supports_job_filter?(jobs_relation, filter)
    supported_job_filters(jobs_relation).include?(filter)
  end

  # List of filters supported natively. Non-supported filters are done in memory.
  def supported_job_filters(jobs_relation)
    []
  end

  def supports_queue_pausing?
    true
  end

  def exposes_workers?
    false
  end

  def supports_recurring_tasks?
    false
  end

  # Returns an array with the list of recurring tasks. Each task is represented as a hash
  # with these attributes:
  #   {
  #     id: "periodic-job",
  #     job_class_name: "MyJob",
  #     arguments: [ 123, { arg: :value }]
  #     schedule: "every monday at 9 am"
  #   }
  def recurring_tasks
    if supports_recurring_tasks?
      raise_incompatible_adapter_error_from :recurring_tasks
    end
  end

  # Returns a recurring task represented by a hash as indicated above
  def find_recurring_task(recurring_task_id)
    if supports_recurring_tasks?
      raise_incompatible_adapter_error_from :find_recurring_task
    end
  end


  # Returns an array with the list of workers. Each worker is represented as a hash
  # with these attributes:
  #   {
  #     id: 123,
  #     name: "worker-name",
  #     hostname: "hey-default-101",
  #     last_heartbeat_at: Fri, 26 Jan 2024 20:31:09.652174000 UTC +00:00,
  #     configuration: { ... }
  #     raw_data: { ... }
  #   }
  def workers
    if exposes_workers?
      raise_incompatible_adapter_error_from :workers
    end
  end

  # Returns a worker represented by a hash as indicated above
  def find_worker(worker_id)
    if exposes_workers?
      raise_incompatible_adapter_error_from :find_worker
    end
  end


  # Returns an array with the list of queues. Each queue is represented as a hash
  # with these attributes:
  #   {
  #     name: "queue_name",
  #     size: 1,
  #     active: true
  #   }
  def queues
    raise_incompatible_adapter_error_from :queue_names
  end

  def queue_size(queue_name)
    raise_incompatible_adapter_error_from :queue_size
  end

  def clear_queue(queue_name)
    raise_incompatible_adapter_error_from :clear_queue
  end

  def pause_queue(queue_name)
    if supports_queue_pausing?
      raise_incompatible_adapter_error_from :pause_queue
    end
  end

  def resume_queue(queue_name)
    if supports_queue_pausing?
      raise_incompatible_adapter_error_from :resume_queue
    end
  end

  def queue_paused?(queue_name)
    if supports_queue_pausing?
      raise_incompatible_adapter_error_from :queue_paused?
    end
  end

  def jobs_count(jobs_relation)
    raise_incompatible_adapter_error_from :jobs_count
  end

  def fetch_jobs(jobs_relation)
    raise_incompatible_adapter_error_from :fetch_jobs
  end

  def retry_all_jobs(jobs_relation)
    raise_incompatible_adapter_error_from :retry_all_jobs
  end

  def retry_job(job, jobs_relation)
    raise_incompatible_adapter_error_from :retry_job
  end

  def discard_all_jobs(jobs_relation)
    raise_incompatible_adapter_error_from :discard_all_jobs
  end

  def discard_job(job, jobs_relation)
    raise_incompatible_adapter_error_from :discard_job
  end

  def dispatch_job(job, jobs_relation)
    raise_incompatible_adapter_error_from :dispatch_job
  end

  def find_job(job_id, *)
    raise_incompatible_adapter_error_from :find_job
  end

  private
    def raise_incompatible_adapter_error_from(method_name)
      raise MissionControl::Jobs::Errors::IncompatibleAdapter, "Adapter #{ActiveJob.adapter_name(self)} must implement `#{method_name}`"
    end
end
