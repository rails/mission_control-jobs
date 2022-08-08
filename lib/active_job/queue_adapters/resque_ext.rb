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
        Resque.queue_sizes.inject(0) { |sum, (_queue_name, queue_size)| sum + queue_size }
    when :failed
        Resque.data_store.num_failed
    else
        raise ActiveJob::Errors::QueryError.new(jobs_relation), "Status not supported: #{status}"
    end
  end

  def fetch_jobs(jobs_relation)
    fetch_resque_jobs(jobs_relation).collect { |resque_job| deserialize_resque_job(resque_job) }
  end

  private
    def fetch_resque_jobs(jobs_relation)
      if jobs_relation.failed?
        Resque::Failure.all(jobs_relation.offset_value, jobs_relation.limit_value)
      else
        unless jobs_relation.queue_name.present?
          raise ActiveJob::Errors::QueryError.new(jobs_relation), "This adapter only supports fetching failed jobs when no queue name is provided"
        end
        Resque.peek(jobs_relation.queue_name, jobs_relation.offset_value, jobs_relation.limit_value)
      end
    end

    def deserialize_resque_job(resque_job_hash)
      ActiveJob::Base.deserialize(resque_job_hash.dig("payload", "args")&.first).tap do |job|
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
