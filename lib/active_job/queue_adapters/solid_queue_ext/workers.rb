module ActiveJob::QueueAdapters::SolidQueueExt::Workers
  def exposes_workers?
    true
  end

  def fetch_workers(workers_relation)
    workers(workers_relation).collect do |process|
      worker_from_solid_queue_process(process)
    end
  end

  def count_workers(workers_relation)
    workers(workers_relation).count
  end

  def find_worker(worker_id)
    if process = SolidQueue::Process.find_by(id: worker_id)
      worker_attributes_from_solid_queue_process(process)
    end
  end

  private

    def workers(workers_relation)
      SolidQueue::Process.where(kind: "Worker")
        .then { |workers| filter_by_hostname(workers, workers_relation.hostname) }
        .then { |workers| filter_by_name(workers, workers_relation.name) }
        .then { |workers| limit(workers, workers_relation.limit_value) }
        .then { |workers| offset(workers, workers_relation.offset_value) }
    end

    def filter_by_hostname(workers, hostname)
      hostname.present? ? workers.where(hostname: hostname) : workers
    end

    def filter_by_name(workers, name)
      name.present? ? workers.where(pid: name) : workers
    end

    def limit(workers, limit)
      workers.limit(limit)
    end

    def offset(workers, offset)
      workers.offset(offset)
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
