module MissionControl::Jobs::Server::Batches
  def batches
    queue_adapter.batches.collect do |batch|
      MissionControl::Jobs::Batch.new(queue_adapter: queue_adapter, **batch)
    end
  end

  def find_batch(batch_id)
    if batch = queue_adapter.find_batch(batch_id)
      MissionControl::Jobs::Batch.new(queue_adapter: queue_adapter, **batch)
    else
      raise MissionControl::Jobs::Errors::ResourceNotFound, "Batch with id '#{batch_id}' not found"
    end
  end
end
