module ActiveJob::QueueAdapters::SolidQueueExt::Batches
  BATCHES_LIMIT = 100

  def supports_batches?
    true
  end

  def batches
    SolidQueue::Batch.order(id: :desc).limit(BATCHES_LIMIT).collect do |batch|
      batch_attributes_from_solid_queue_batch(batch)
    end
  end

  def find_batch(batch_id)
    if batch = SolidQueue::Batch.find_by(id: batch_id)
      batch_attributes_from_solid_queue_batch(batch)
    end
  end

  private
    def batch_attributes_from_solid_queue_batch(batch)
      {
        id: batch.id,
        description: batch.description,
        status: batch.status,
        total_jobs: batch.total_jobs,
        completed_jobs: batch.completed_jobs,
        failed_jobs: batch.failed_jobs,
        pending_jobs: batch.pending_jobs,
        progress_percentage: batch.progress_percentage,
        metadata: batch.metadata,
        enqueued_at: batch.enqueued_at,
        finished_at: batch.finished_at
      }
    end
end
