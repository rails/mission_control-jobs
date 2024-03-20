module ActiveJob::QueueAdapters::SolidQueueExt::Workers
  def exposes_workers?
    true
  end

  def fetch_workers(workers_relation)
    workers = SolidQueue::Process.where(kind: "Worker").offset(workers_relation.offset_value).limit(workers_relation.limit_value)
    workers.collect { |process| worker_from_solid_queue_process(process) }
  end

  def find_worker(worker_id)
    if process = SolidQueue::Process.find_by(id: worker_id)
      worker_attributes_from_solid_queue_process(process)
    end
  end

  private
    def worker_attributes_from_solid_queue_process(process)
      {
        id: process.id,
        name: "PID: #{process.pid}",
        hostname: process.hostname,
        last_heartbeat_at: process.last_heartbeat_at,
        configuration: process.metadata,
        raw_data: process.as_json
      }
    end
end
