module ActiveJob::QueueAdapters::SolidQueueExt
  include MissionControl::Jobs::Adapter

  def queue_names
    SolidQueue::Queue.all.map(&:name)
  end

  def queues
    SolidQueue::Queue.all.collect do |queue|
      {
        name: queue.name,
        size: queue.size,
        active: !queue.paused?
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

  def jobs_count(jobs_relation)
    RelationAdapter.new(jobs_relation).count
  end

  def fetch_jobs(jobs_relation)
    find_solid_queue_jobs_within(jobs_relation).map { |job| deserialize_and_proxy_job(job) }
  end

  def support_class_name_filtering?
    true
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
      deserialize_and_proxy_job job
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

    def deserialize_and_proxy_job(solid_queue_job)
      ActiveJob::JobProxy.new(solid_queue_job.arguments).tap do |job|
        job.last_execution_error = execution_error_from_job(solid_queue_job)
        job.raw_data = solid_queue_job.as_json
        job.failed_at = solid_queue_job.failed_execution&.created_at
      end
    end

    def execution_error_from_job(solid_queue_job)
      if solid_queue_job.failed?
        ActiveJob::ExecutionError.new \
          error_class: solid_queue_job.failed_execution.exception_class,
          message: solid_queue_job.failed_execution.message,
          backtrace: solid_queue_job.failed_execution.backtrace
      end
    end

    class RelationAdapter
      def initialize(jobs_relation)
        @jobs_relation = jobs_relation
      end

      def jobs
        executions.map(&:job)
      end

      def count
        executions.count
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

        delegate :queue_name, :status, :limit_value, :offset_value, :job_class_name, :default_page_size, to: :jobs_relation

        def executions
          execution_class_by_status.includes(job: :failed_execution).order(:job_id)
            .then { |executions| filter_by_queue(executions) }
            .then { |executions| filter_by_class(executions) }
            .then { |executions| limit(executions) }
            .then { |executions| offset(executions) }
        end

        def matches_relation_filters?(job)
          matches_status?(job) && matches_queue?(job)
        end

        def execution_class_by_status
          case status
          when :pending then SolidQueue::ReadyExecution
          when :failed  then SolidQueue::FailedExecution
          else
            raise ActiveJob::Errors::QueryError, "Status not supported: #{status}"
          end
        end

        def filter_by_queue(executions)
          return executions unless queue_name.present?

          if jobs_relation.failed?
            executions.where(job: { queue_name: queue_name })
          else
            executions.where(queue_name: queue_name)
          end
        end

        def filter_by_class(executions)
          job_class_name.present? ? executions.where(job: { class_name: job_class_name }) : executions
        end

        def limit(executions)
          limit_value.present? ? executions.limit(limit_value) : executions
        end

        def offset(executions)
          offset_value.present? ? executions.offset(offset_value) : executions
        end

        def matches_status?(job)
          case status
          when :pending then job.ready?
          when :failed  then job.failed?
          else          true
          end
        end

        def matches_queue?(job)
          queue_name.present? ? job.queue_name == queue_name : true
        end
    end
end
