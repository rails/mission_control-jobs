module MissionControl::Jobs::Server::Workers
  def workers_relation
    MissionControl::Jobs::WorkersRelation.new(queue_adapter: queue_adapter)
  end

  def find_worker(worker_id)
    if worker = queue_adapter.find_worker(worker_id)
      MissionControl::Jobs::Worker.new(queue_adapter: queue_adapter, **worker)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "Worker with id '#{worker_id}' not found"
    end
  end
end
