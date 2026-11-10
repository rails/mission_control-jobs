module ActiveJob::QueueAdapters::SolidQueueExt::Batches
  # Batches shipped in Solid Queue 1.7 as an optional migration, so the
  # constant existing doesn't mean the tables do.
  def supports_batches?
    SolidQueue.const_defined?(:Batch, false) && SolidQueue::Batch.migrated?
  end

  def fetch_batches(batches_relation)
    batches = batches_scope(batches_relation.status).order(id: :desc)
      .offset(batches_relation.offset_value).limit(batches_relation.limit_value).to_a

    # Progress comes from the tracking rows, which are always counted, so the
    # listing only counts failures on top. The batch page needs the rest.
    attributes_for_batches(batches, job_statuses_to_count: [ :failed ])
  end

  def count_batches(batches_relation)
    count_limit = MissionControl::Jobs.internal_query_count_limit + 1
    limited_count = batches_scope(batches_relation.status).limit(count_limit).count
    (limited_count == count_limit) ? Float::INFINITY : limited_count
  end

  def find_batch(batch_id)
    if batch = SolidQueue::Batch.find_by(id: batch_id)
      attributes_for_batches([ batch ], job_statuses_to_count: job_execution_classes.keys).first
    end
  end

  private
    def batches_scope(status)
      case status
      when :finished   then SolidQueue::Batch.finished
      when :unfinished then SolidQueue::Batch.unfinished
      when :failed     then SolidQueue::Batch.failed
      else SolidQueue::Batch.all
      end
    end

    # Finished batches froze their counters on the row at finalize time, so
    # only live batches pay for job counting — a page of history runs no
    # count queries at all.
    def attributes_for_batches(batches, job_statuses_to_count:)
      counts_by_status = job_counts_for(batches.reject(&:finished_at?), job_statuses_to_count)

      batches.collect do |batch|
        job_counts = counts_by_status.transform_values { |counts_by_batch_id| counts_by_batch_id.fetch(batch.id, 0) }
        batch_attributes_from_solid_queue_batch(batch, job_counts)
      end
    end

    # One grouped count per status covers every batch given, so a page costs the
    # same number of queries as a single batch:
    #
    #   { failed: { 12 => 1 }, outstanding: { 12 => 4, 13 => 9 } }
    def job_counts_for(batches, job_statuses_to_count)
      return {} if batches.none?

      batch_ids = batches.map(&:id)
      jobs_in_batches = SolidQueue::Job.where(batch_id: batch_ids).group(:batch_id)

      counts_by_status = job_execution_classes.slice(*job_statuses_to_count).transform_values do |execution_class|
        execution_class.joins(:job).merge(jobs_in_batches).count
      end

      counts_by_status.merge(outstanding: SolidQueue::BatchExecution.where(batch_id: batch_ids).group(:batch_id).count)
    end

    def batch_attributes_from_solid_queue_batch(batch, job_counts)
      if batch.finished_at.present?
        # Raw column reads: the gem's counter methods compute with live COUNT
        # queries, and finalizing the batch already froze these on the row.
        completed_jobs = batch[:completed_jobs]
        job_counts = { pending: 0, in_progress: 0, blocked: 0, scheduled: 0, failed: batch[:failed_jobs] }
        outstanding_jobs = 0
      else
        # +total_jobs+ counts logical jobs while the tracking rows count attempts, so a
        # retry overlapping its previous attempt can outnumber them. Clamp like
        # +SolidQueue::Batch::Status+ does.
        outstanding_jobs = job_counts[:outstanding]
        completed_jobs = [ batch.total_jobs - outstanding_jobs - job_counts[:failed], 0 ].max
      end

      {
        id: batch.id,
        description: batch.description,
        status: batch.status,
        total_jobs: batch.total_jobs,
        completed_jobs: completed_jobs,
        failed_jobs: job_counts[:failed],
        pending_jobs: job_counts[:pending],
        in_progress_jobs: job_counts[:in_progress],
        blocked_jobs: job_counts[:blocked],
        scheduled_jobs: job_counts[:scheduled],
        progress_percentage: progress_percentage(batch.total_jobs, outstanding_jobs),
        metadata: batch.metadata,
        enqueued_at: batch.enqueued_at,
        finished_at: batch.finished_at
      }
    end

    def progress_percentage(total_jobs, outstanding_jobs)
      return 0 if total_jobs == 0

      ([ total_jobs - outstanding_jobs, 0 ].max * 100.0 / total_jobs).round(2)
    end

    def job_execution_classes
      {
        pending: SolidQueue::ReadyExecution,
        failed: SolidQueue::FailedExecution,
        in_progress: SolidQueue::ClaimedExecution,
        blocked: SolidQueue::BlockedExecution,
        scheduled: SolidQueue::ScheduledExecution
      }
    end
end
