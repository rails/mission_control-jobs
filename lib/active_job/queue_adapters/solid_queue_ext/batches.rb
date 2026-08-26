module ActiveJob::QueueAdapters::SolidQueueExt::Batches
  # Batches shipped in Solid Queue 1.7 as an optional migration, so the
  # constant existing doesn't mean the tables do.
  def supports_batches?
    SolidQueue.const_defined?(:Batch, false) && SolidQueue::Batch.migrated?
  end

  def fetch_batches(batches_relation)
    status = batches_relation.status

    batches_for_listing(status).merge(batches_scope(status)).order(id: :desc)
      .offset(batches_relation.offset_value).limit(batches_relation.limit_value).collect do |batch|
        batch_attributes_from_solid_queue_batch(batch)
      end
  end

  def count_batches(batches_relation)
    count_limit = MissionControl::Jobs.internal_query_count_limit + 1
    limited_count = batches_scope(batches_relation.status).limit(count_limit).count
    (limited_count == count_limit) ? Float::INFINITY : limited_count
  end

  def find_batch(batch_id)
    if batch = solid_queue_batches.find_by(id: batch_id)
      batch_attributes_from_solid_queue_batch(batch)
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

    # Finished/failed batches already store counters on the row. Skip live job-count
    # subqueries there so listing millions of historical batches stays cheap.
    def batches_for_listing(status)
      case status
      when :finished, :failed then SolidQueue::Batch.all
      else solid_queue_batches
      end
    end

    def batch_attributes_from_solid_queue_batch(batch)
      job_counts = job_counts_from_solid_queue_batch(batch)
      unfinished_jobs = batch_count(batch, :unfinished)

      if batch.finished_at.present?
        completed_jobs = batch[:completed_jobs]
        job_counts = job_counts.transform_values { 0 }.merge(failed: batch[:failed_jobs])
        unfinished_jobs = 0
      else
        # +total_jobs+ counts logical jobs while the tracking rows count attempts, so a
        # retry overlapping its previous attempt can outnumber them. Clamp like
        # +SolidQueue::Batch::Status+ does.
        completed_jobs = [ batch.total_jobs - unfinished_jobs - job_counts[:failed], 0 ].max
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
        progress_percentage: progress_percentage(batch.total_jobs, unfinished_jobs),
        metadata: batch.metadata,
        enqueued_at: batch.enqueued_at,
        finished_at: batch.finished_at
      }
    end

    def solid_queue_batches
      selects = [ "#{SolidQueue::Batch.quoted_table_name}.*", unfinished_jobs_count_select ]
      selects.concat job_execution_classes.map { |status, model| job_count_select(status, model) }
      SolidQueue::Batch.select(*selects)
    end

    # CASE keeps Postgres from evaluating the correlated COUNT for finished rows
    # when an "all" listing mixes finished and unfinished batches.
    def unfinished_jobs_count_select
      batch_executions_table = SolidQueue::BatchExecution.quoted_table_name
      batches_table = SolidQueue::Batch.quoted_table_name
      batch_id = quote_column_name("batch_id")
      id = quote_column_name("id")
      finished_at = quote_column_name("finished_at")
      live_count = "SELECT COUNT(*) FROM #{batch_executions_table} WHERE #{batch_executions_table}.#{batch_id} = #{batches_table}.#{id}"

      "(CASE WHEN #{batches_table}.#{finished_at} IS NOT NULL THEN 0 ELSE (#{live_count}) END) AS #{quote_column_name(batch_count_attribute(:unfinished))}"
    end

    def job_count_select(status, execution_model)
      executions_table = execution_model.quoted_table_name
      jobs_table = SolidQueue::Job.quoted_table_name
      batches_table = SolidQueue::Batch.quoted_table_name
      job_id = quote_column_name("job_id")
      batch_id = quote_column_name("batch_id")
      id = quote_column_name("id")
      finished_at = quote_column_name("finished_at")
      finished_value = status == :failed ? "#{batches_table}.#{quote_column_name("failed_jobs")}" : "0"
      live_count = "SELECT COUNT(*) FROM #{executions_table} INNER JOIN #{jobs_table} ON #{jobs_table}.#{id} = #{executions_table}.#{job_id} WHERE #{jobs_table}.#{batch_id} = #{batches_table}.#{id}"

      "(CASE WHEN #{batches_table}.#{finished_at} IS NOT NULL THEN #{finished_value} ELSE (#{live_count}) END) AS #{quote_column_name(batch_count_attribute(status))}"
    end

    def job_counts_from_solid_queue_batch(batch)
      job_execution_classes.keys.to_h { |status| [ status, batch_count(batch, status) ] }
    end

    def batch_count(batch, status)
      batch[batch_count_attribute(status)].to_i
    end

    def batch_count_attribute(status)
      "mission_control_#{status}_jobs"
    end

    def progress_percentage(total_jobs, unfinished_jobs)
      return 0 if total_jobs == 0

      ([ total_jobs - unfinished_jobs, 0 ].max * 100.0 / total_jobs).round(2)
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

    def quote_column_name(name)
      SolidQueue::Batch.connection.quote_column_name(name)
    end
end
