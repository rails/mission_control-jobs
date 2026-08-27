module MissionControl::Jobs::Server::Batches
  def batches(status: nil)
    MissionControl::Jobs::BatchesRelation.new(queue_adapter: queue_adapter, status: status)
  end

  def find_batch(batch_id)
    if batch = queue_adapter.find_batch(batch_id)
      MissionControl::Jobs::Batch.new(queue_adapter: queue_adapter, **batch)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "Batch with id '#{batch_id}' not found"
    end
  end
end
