module MissionControl::Jobs::Server::Workers
  def workers
    queue_adapter.workers.collect do |worker|
      MissionControl::Jobs::Worker.new(queue_adapter: queue_adapter, **worker)
    end
  end

  def find_worker(worker_id)
    if worker = queue_adapter.find_worker(worker_id)
      MissionControl::Jobs::Worker.new(queue_adapter: queue_adapter, **worker)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "No worker found with ID #{worker_id}"
    end
  end
end
