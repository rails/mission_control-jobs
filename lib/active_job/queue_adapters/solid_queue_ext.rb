module ActiveJob::QueueAdapters::SolidQueueExt
  include MissionControl::Jobs::Adapter
  include RecurringTasks, Workers

  def queues
    queues = SolidQueue::Queue.all
    pauses = SolidQueue::Pause.where(queue_name: queues.map(&:name)).index_by(&:queue_name)

    queues.collect do |queue|
      {
        name: queue.name,
        size: queue.size,
        active: pauses[queue.name].nil?
      }
    end
  end

  def queue_size(queue_name)
    find_queue_by_name(queue_name).size
  end

  def clear_queue(queue_name)
    find_queue_by_name(queue_name).clear
  end

  def pause_queue(queue_name)
    find_queue_by_name(queue_name).pause
  end

  def resume_queue(queue_name)
    find_queue_by_name(queue_name).resume
  end

  def queue_paused?(queue_name)
    find_queue_by_name(queue_name).paused?
  end

  def supported_job_statuses
    SolidQueueJobs::STATUS_MAP.keys
  end

  def supported_job_filters(*)
    [ :queue_name, :job_class_name ]
  end

  def jobs_count(jobs_relation)
    SolidQueueJobs.new(jobs_relation).count
  end

  def fetch_jobs(jobs_relation)
    SolidQueueJobs.new(jobs_relation).jobs.map do |job|
      deserialize_and_proxy_solid_queue_job(job, jobs_relation.status)
    end
  end

  def retry_all_jobs(jobs_relation)
    SolidQueueJobs.new(jobs_relation).retry_all
  end

  def retry_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).retry
  end

  def discard_all_jobs(jobs_relation)
    SolidQueueJobs.new(jobs_relation).discard_all
  end

  def discard_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).discard
  end

  def dispatch_job(job, jobs_relation)
    dispatch_immediately find_solid_queue_job!(job.job_id, jobs_relation)
  end

  def find_job(job_id, *)
    if job = SolidQueue::Job.where(active_job_id: job_id).order(:id).last
      deserialize_and_proxy_solid_queue_job job
    end
  end

  private
    def find_queue_by_name(queue_name)
      SolidQueue::Queue.find_by_name(queue_name)
    end

    def find_solid_queue_job!(job_id, jobs_relation)
      find_solid_queue_job(job_id, jobs_relation) or raise ActiveJob::Errors::JobNotFoundError.new(job_id, jobs_relation)
    end

    def find_solid_queue_job(job_id, jobs_relation)
      SolidQueueJobs.new(jobs_relation).find_job(job_id)
    end

    def deserialize_and_proxy_solid_queue_job(solid_queue_job, job_status = nil)
      job_status ||= status_from_solid_queue_job(solid_queue_job)

      ActiveJob::JobProxy.new(solid_queue_job.arguments).tap do |job|
        job.status = job_status
        job.last_execution_error = execution_error_from_solid_queue_job(solid_queue_job) if job_status == :failed
        job.raw_data = solid_queue_job.as_json
        job.failed_at = solid_queue_job&.failed_execution&.created_at if job_status == :failed
        job.finished_at = solid_queue_job.finished_at
        job.blocked_by = solid_queue_job.concurrency_key
        job.blocked_until = solid_queue_job&.blocked_execution&.expires_at if job_status == :blocked
        job.worker_id = solid_queue_job&.claimed_execution&.process_id if job_status == :in_progress
        job.started_at = solid_queue_job&.claimed_execution&.created_at if job_status == :in_progress
        job.scheduled_at = solid_queue_job.scheduled_at
      end
    end

    def status_from_solid_queue_job(solid_queue_job)
      SolidQueueJobs::STATUS_MAP.invert[solid_queue_job.status]
    end

    def execution_error_from_solid_queue_job(solid_queue_job)
      if solid_queue_job.failed?
        ActiveJob::ExecutionError.new \
          error_class: solid_queue_job.failed_execution.exception_class,
          message: solid_queue_job.failed_execution.message,
          backtrace: solid_queue_job.failed_execution.backtrace || []
      end
    end

    def dispatch_immediately(job)
      SolidQueue::Job.transaction do
        job.dispatch_bypassing_concurrency_limits
        job.blocked_execution.destroy!
      end
    end

    class SolidQueueJobs
      STATUS_MAP = {
        pending: :ready,
        failed: :failed,
        in_progress: :claimed,
        blocked: :blocked,
        scheduled: :scheduled,
        finished: :finished
      }

      def initialize(jobs_relation)
        @jobs_relation = jobs_relation
      end

      def jobs
        solid_queue_status.finished? ? order_finished_jobs(finished_jobs) : order_executions(executions).map(&:job).compact
      end

      def count
        limit_value_provided? ? direct_count : internally_limited_count
      end

      def find_job(active_job_id)
        if job = SolidQueue::Job.where(active_job_id: active_job_id).order(:id).last
          job if matches_relation_filters?(job)
        end
      end

      def discard_all
        execution_class_by_status.discard_all_from_jobs(jobs)
      end

      def retry_all
        SolidQueue::FailedExecution.retry_all(jobs)
      end

      private
        attr_reader :jobs_relation

        delegate :queue_name, :limit_value, :limit_value_provided?, :offset_value, :job_class_name,
          :default_page_size, :worker_id, :recurring_task_id, to: :jobs_relation

        def executions
          execution_class_by_status
            .then { |executions| include_execution_association(executions) }
            .then { |executions| filter_executions_by_queue(executions) }
            .then { |executions| filter_executions_by_class(executions) }
            .then { |executions| filter_executions_by_process_id(executions) }
            .then { |executions| filter_executions_by_task_key(executions) }
            .then { |executions| limit(executions) }
            .then { |executions| offset(executions) }
        end

        def finished_jobs
          SolidQueue::Job.finished
            .then { |jobs| filter_jobs_by_queue(jobs) }
            .then { |jobs| filter_jobs_by_class(jobs) }
            .then { |jobs| limit(jobs) }
            .then { |jobs| offset(jobs) }
        end

        def order_finished_jobs(jobs)
          jobs.order(finished_at: :desc)
        end

        def order_executions(executions)
          case
            # Follow polling order for scheduled executions, the rest by job_id, desc or asc
          when solid_queue_status.scheduled? then executions.ordered
          when recurring_task_id.present?    then executions.order(job_id: :desc)
          else executions.order(job_id: :asc)
          end
        end

        def matches_relation_filters?(job)
          matches_status?(job) && matches_queue_name?(job)
        end

        def direct_count
          solid_queue_status.finished? ? finished_jobs.count : executions.count
        end

        def internally_limited_count
          count_limit = MissionControl::Jobs.internal_query_count_limit + 1
          limited_count = solid_queue_status.finished? ? finished_jobs.limit(count_limit).count : executions.limit(count_limit).count
          (limited_count == count_limit) ? Float::INFINITY : limited_count
        end

        def execution_class_by_status
          if recurring_task_id.present?
            SolidQueue::RecurringExecution
          elsif solid_queue_status.present? && !solid_queue_status.finished?
            "SolidQueue::#{solid_queue_status.capitalize}Execution".safe_constantize
          else
            raise ActiveJob::Errors::QueryError, "Status not supported: #{jobs_relation.status}"
          end
        end

        def include_execution_association(executions)
          solid_queue_status.present? ? executions.includes(job: "#{solid_queue_status}_execution") : executions.includes(:job)
        end

        def filter_executions_by_queue(executions)
          return executions unless queue_name.present?

          if solid_queue_status.ready?
            executions.where(queue_name: queue_name)
          else
            executions.where(job: { queue_name: queue_name })
          end
        end

        def filter_jobs_by_queue(jobs)
          queue_name.present? ? jobs.where(queue_name: queue_name) : jobs
        end

        def filter_executions_by_class(executions)
          job_class_name.present? ? executions.where(job: { class_name: job_class_name }) : executions
        end

        def filter_executions_by_process_id(executions)
          return executions unless worker_id.present?

          if solid_queue_status.claimed?
            executions.where(process_id: worker_id)
          else
            raise ActiveJob::Errors::QueryError, "Filtering by worker id is not supported for status #{jobs_relation.status}"
          end
        end

        def filter_executions_by_task_key(executions)
          recurring_task_id.present? ? executions.where(task_key: recurring_task_id) : executions
        end

        def filter_jobs_by_class(jobs)
          job_class_name.present? ? jobs.where(class_name: job_class_name) : jobs
        end

        def limit(executions_or_jobs)
          limit_value.present? ? executions_or_jobs.limit(limit_value) : executions_or_jobs
        end

        def offset(executions_or_jobs)
          offset_value.present? ? executions_or_jobs.offset(offset_value) : executions_or_jobs
        end

        def matches_status?(job)
          solid_queue_status.blank? || job.public_send("#{solid_queue_status}?")
        end

        def matches_queue_name?(job)
          queue_name.blank? || job.queue_name == queue_name
        end

        def solid_queue_status
          STATUS_MAP[jobs_relation.status].to_s.inquiry
        end
    end
end
