module ActiveJob::QueueAdapters::SolidQueueExt::Workers
  def exposes_workers?
    true
  end

  def fetch_workers(workers_relation)
    solid_queue_processes_from_workers_relation(workers_relation).collect do |process|
      worker_from_solid_queue_process(process)
    end
  end

  def count_workers(workers_relation)
    solid_queue_processes_from_workers_relation(workers_relation).count
  end

  def find_worker(worker_id)
    if process = SolidQueue::Process.find_by(id: worker_id)
      worker_attributes_from_solid_queue_process(process)
    end
  end

  private
    def solid_queue_processes_from_workers_relation(relation)
      SolidQueue::Process.where(kind: "Worker").offset(relation.offset_value).limit(relation.limit_value)
    end

    def worker_from_solid_queue_process(process)
      MissionControl::Jobs::Worker.new(queue_adapter: self, **worker_attributes_from_solid_queue_process(process))
    end

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
