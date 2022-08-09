module ActiveJob::QueueAdapters::ResqueExt
  def queue_names
    Resque.queues
  end

  def queue_size(queue_name)
    Resque.size queue_name
  end

  def clear_queue(queue_name)
    Resque.remove_queue(queue_name)
  end

  def pause_queue(queue_name)
    ResquePauseHelper.pause(queue_name)
  end

  def resume_queue(queue_name)
    ResquePauseHelper.unpause(queue_name)
  end

  def queue_paused?(queue_name)
    ResquePauseHelper.paused?(queue_name)
  end

  def jobs_count(jobs_relation)
    case jobs_relation.status
    when :pending
      pending_jobs_count(jobs_relation)
    when :failed
      failed_jobs_count
    else
      raise ActiveJob::Errors::QueryError, "Status not supported: #{status}"
    end
  end

  def fetch_jobs(jobs_relation)
    fetch_resque_jobs(jobs_relation).collect { |resque_job| deserialize_resque_job(resque_job) }
  end

  def support_class_name_filtering?
    false
  end

  private
    def pending_jobs_count(jobs_relation)
      Resque.queue_sizes.inject(0) do |sum, (queue_name, queue_size)|
        if jobs_relation.queue_name.blank? || jobs_relation.queue_name == queue_name
          sum + queue_size
        else
          sum
        end
      end
    end

    def failed_jobs_count
      Resque.data_store.num_failed
    end

    def fetch_resque_jobs(jobs_relation)
      if jobs_relation.failed?
        fetch_failed_resque_jobs(jobs_relation)
      else
        fetch_queue_resque_jobs(jobs_relation)
      end
    end

    def fetch_failed_resque_jobs(jobs_relation)
      Resque::Failure.all(jobs_relation.offset_value, jobs_relation.limit_value)
    end

    def fetch_queue_resque_jobs(jobs_relation)
      unless jobs_relation.queue_name.present?
        raise ActiveJob::Errors::QueryError, "This adapter only supports fetching failed jobs when no queue name is provided"
      end
      Resque.peek(jobs_relation.queue_name, jobs_relation.offset_value, jobs_relation.limit_value)
    end

    def deserialize_resque_job(resque_job_hash)
      args_hash = resque_job_hash.dig("payload", "args") || resque_job_hash.dig("args")
      ActiveJob::JobProxy.new(args_hash&.first).tap do |job|
        job.last_execution_error = execution_error_from_resque_job(resque_job_hash)
      end
    end

    def execution_error_from_resque_job(resque_job_hash)
      if resque_job_hash["exception"].present?
        ActiveJob::ExecutionError.new \
          error_class: resque_job_hash["exception"],
          message: resque_job_hash["error"],
          backtrace: resque_job_hash["backtrace"]
      end
    end
end
