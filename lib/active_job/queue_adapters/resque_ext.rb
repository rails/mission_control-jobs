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
end
