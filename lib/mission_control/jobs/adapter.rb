module MissionControl::Jobs::Adapter
  def activating(&block)
    block.call
  end

  def supported_statuses
    # All adapters need to support these at a minimum
    [ :pending, :failed, :scheduled ]
  end

  def supports_filter?(jobs_relation, filter)
    supported_filters(jobs_relation).include?(filter)
  end

  # List of filters supported natively. Non-supported filters are done in memory.
  def supported_filters(jobs_relation)
    []
  end

  def supports_queue_pausing?
    true
  end

  def exposes_workers?
    false
  end

  # Returns an array with the list of workers. Each worker is represented as a hash
  # with these attributes:
  #   {
  #     id: 123,
  #     name: "adapter-name",
  #     hostname: "hey-default-101",
  #     last_heartbeat_at: Fri, 26 Jan 2024 20:31:09.652174000 UTC +00:00,
  #     configuration: { ... }
  #     raw_data: { ... }
  #   }
  def workers
    if exposes_workers?
      raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `workers`")
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
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `queue_names`")
  end

  def queue_size(queue_name)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `queue_size`")
  end

  def clear_queue(queue_name)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `clear_queue`")
  end

  def pause_queue(queue_name)
    if supports_queue_pausing?
      raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `pause_queue`")
    end
  end

  def resume_queue(queue_name)
    if supports_queue_pausing?
      raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `resume_queue`")
    end
  end

  def queue_paused?(queue_name)
    if supports_queue_pausing?
      raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `queue_paused?`")
    end
  end

  def jobs_count(jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `jobs_count`")
  end

  def fetch_jobs(jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `fetch_jobs`")
  end

  def retry_all_jobs(jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `retry_all_jobs`")
  end

  def retry_job(job, jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `retry_job`")
  end

  def discard_all_jobs(jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `discard_all_jobs`")
  end

  def discard_job(job, jobs_relation)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `discard_job`")
  end

  def find_job(job_id, *)
    raise MissionControl::Jobs::Errors::IncompatibleAdapter("Adapter must implement `find_job`")
  end
end
