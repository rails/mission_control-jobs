module ActiveJob::QueueAdapters::SolidQueueExt::Batches
  BATCHES_LIMIT = 100
  BATCH_COLUMNS = %w[ id description metadata total_jobs completed_jobs failed_jobs enqueued_at finished_at failed_at ]
  BATCH_EXECUTION_COLUMNS = %w[ job_id batch_id ]
  JOB_COLUMNS = %w[ id batch_id ]
  JOB_EXECUTION_CLASS_NAMES = {
    pending: "SolidQueue::ReadyExecution",
    failed: "SolidQueue::FailedExecution",
    in_progress: "SolidQueue::ClaimedExecution",
    blocked: "SolidQueue::BlockedExecution",
    scheduled: "SolidQueue::ScheduledExecution"
  }

  def supports_batches?
    solid_queue_batch_models_available? &&
      SolidQueue::Batch.method_defined?(:status) &&
      solid_queue_batch_schema_available?
  rescue ActiveRecord::ActiveRecordError, NameError
    false
  end

  def batches(status: nil, offset: 0, limit: BATCHES_LIMIT)
    batches_relation(status).merge(batches_scope(status)).order(id: :desc).offset(offset).limit(limit).collect do |batch|
      batch_attributes_from_solid_queue_batch(batch)
    end
  end

  def batches_count(status: nil)
    count_limit = MissionControl::Jobs.internal_query_count_limit + 1
    limited_count = batches_scope(status).limit(count_limit).count
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
    def batches_relation(status)
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
        completed_jobs = batch.total_jobs - unfinished_jobs - job_counts[:failed]
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

    def solid_queue_batch_models_available?
      %i[ Batch BatchExecution ].all? { |name| SolidQueue.const_defined?(name, false) }
    end

    def solid_queue_batch_schema_available?
      model_has_columns?(SolidQueue::Batch, BATCH_COLUMNS) &&
        model_has_columns?(SolidQueue::BatchExecution, BATCH_EXECUTION_COLUMNS) &&
        model_has_columns?(SolidQueue::Job, JOB_COLUMNS) &&
        job_execution_models.all? { |model| model_has_columns?(model, [ "job_id" ]) }
    end

    def model_has_columns?(model, columns)
      model.table_exists? && columns.all? { |column| model.column_names.include?(column) }
    end

    def solid_queue_batches
      selects = [ "#{SolidQueue::Batch.quoted_table_name}.*", unfinished_jobs_count_select ]
      selects.concat JOB_EXECUTION_CLASS_NAMES.map { |status, class_name| job_count_select(status, class_name.constantize) }
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
      JOB_EXECUTION_CLASS_NAMES.keys.to_h { |status| [ status, batch_count(batch, status) ] }
    end

    def batch_count(batch, status)
      batch[batch_count_attribute(status)].to_i
    end

    def batch_count_attribute(status)
      "mission_control_#{status}_jobs"
    end

    def progress_percentage(total_jobs, unfinished_jobs)
      return 0 if total_jobs == 0

      ((total_jobs - unfinished_jobs) * 100.0 / total_jobs).round(2)
    end

    def job_execution_models
      JOB_EXECUTION_CLASS_NAMES.values.map(&:constantize)
    end

    def quote_column_name(name)
      SolidQueue::Batch.connection.quote_column_name(name)
    end
end
