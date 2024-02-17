module MissionControl::Jobs::Server::Workers
  def workers
    workers = queue_adapter.workers.reduce([]) do |acc, worker|
      acc << MissionControl::Jobs::Worker.new(queue_adapter: queue_adapter, **worker)
    end

    ActiveJob::WorkersRelation.new(workers: workers)
  end

  def find_worker(worker_id)
    if worker = queue_adapter.find_worker(worker_id)
      MissionControl::Jobs::Worker.new(queue_adapter: queue_adapter, **worker)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "No worker found with ID #{worker_id}"
    end
  end
end
