module ActiveJob::QueueAdapters::SolidQueueExt
  include MissionControl::Jobs::Adapter

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

  def supported_statuses
    RelationAdapter::STATUS_MAP.keys
  end

  def supported_filters(*)
    [ :queue_name, :job_class_name ]
  end

  def jobs_count(jobs_relation)
    RelationAdapter.new(jobs_relation).count
  end

  def fetch_jobs(jobs_relation)
    find_solid_queue_jobs_within(jobs_relation).map { |job| deserialize_and_proxy_solid_queue_job(job, jobs_relation.status) }
  end

  def retry_all_jobs(jobs_relation)
    RelationAdapter.new(jobs_relation).retry_all
  end

  def retry_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).retry
  end

  def discard_all_jobs(jobs_relation)
    RelationAdapter.new(jobs_relation).discard_all
  end

  def discard_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).discard
  end

  def find_job(job_id, *)
    if job = SolidQueue::Job.find_by(active_job_id: job_id)
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
      RelationAdapter.new(jobs_relation).find_job(job_id)
    end

    def find_solid_queue_jobs_within(jobs_relation)
      RelationAdapter.new(jobs_relation).jobs
    end

    def deserialize_and_proxy_solid_queue_job(solid_queue_job, job_status = nil)
      job_status ||= solid_queue_job.status

      ActiveJob::JobProxy.new(solid_queue_job.arguments).tap do |job|
        job.last_execution_error = execution_error_from_solid_queue_job(solid_queue_job) if job_status == :failed
        job.raw_data = solid_queue_job.as_json
        job.failed_at = solid_queue_job.failed_execution.created_at if job_status == :failed
        job.finished_at = solid_queue_job.finished_at
        job.status = job_status
      end
    end

    def execution_error_from_solid_queue_job(solid_queue_job)
      if solid_queue_job.failed?
        ActiveJob::ExecutionError.new \
          error_class: solid_queue_job.failed_execution.exception_class,
          message: solid_queue_job.failed_execution.message,
          backtrace: solid_queue_job.failed_execution.backtrace
      end
    end

    class RelationAdapter
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
        status.finished? ? finished_jobs : executions.order(:job_id).map(&:job)
      end

      def count
        status.finished? ? finished_jobs.count : executions.count
      end

      def find_job(active_job_id)
        if job = SolidQueue::Job.find_by(active_job_id: active_job_id)
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

        delegate :queue_name, :limit_value, :offset_value, :job_class_name, :default_page_size, to: :jobs_relation

        def executions
          execution_class_by_status.includes(:job)
            .then { |executions| filter_executions_by_queue(executions) }
            .then { |executions| filter_executions_by_class(executions) }
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

        def matches_relation_filters?(job)
          matches_status?(job) && matches_queue_name?(job)
        end

        def execution_class_by_status
          if status.present? && !status.finished?
            "SolidQueue::#{status.capitalize}Execution".safe_constantize
          else
            raise ActiveJob::Errors::QueryError, "Status not supported: #{status}"
          end
        end

        def filter_executions_by_queue(executions)
          return executions unless queue_name.present?

          if status.ready?
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
          status.blank? || job.public_send("#{status}?")
        end

        def matches_queue_name?(job)
          queue_name.blank? || job.queue_name == queue_name
        end

        def status
          STATUS_MAP[jobs_relation.status].to_s.inquiry
        end
    end
end
