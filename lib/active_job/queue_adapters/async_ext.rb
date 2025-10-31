module ActiveJob::QueueAdapters::AsyncExt
  include MissionControl::Jobs::Adapter

  # List of filters supported natively. Non-supported filters are done in memory.
  def supported_job_filters(jobs_relation)
    []
  end

  def supports_queue_pausing?
    false
  end

  def queues
    []
  end

  def queue_size(*)
    0
  end

  def clear_queue(*)
  end

  def jobs_count(*)
    0
  end

  def fetch_jobs(*)
    []
  end

  def retry_all_jobs(*)
  end

  def retry_job(job, *)
  end

  def discard_all_jobs(*)
  end

  def discard_job(*)
  end

  def dispatch_job(*)
  end

  def find_job(*)
  end
end
