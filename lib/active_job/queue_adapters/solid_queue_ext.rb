module ActiveJob::QueueAdapters::SolidQueueExt
  def activating(&block)
    block.call
  end

  def queue_names
    SolidQueue::Queue.all.map(&:name)
  end

  # Returns an array with the list of queues. Each queue is represented as a hash
  # with these attributes:
  #   {
  #    "name": "queue_name",
  #    "size": 1,
  #    active: true
  #   }
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
    find_solid_queue_jobs_within(jobs_relation).count
  end

  def fetch_jobs(jobs_relation)
    find_solid_queue_jobs_within(jobs_relation).map { |job| deserialize_and_proxy_job(job) }
  end

  def support_class_name_filtering?
    true
  end

  def support_pausing_queues?
    false
  end

  def retry_all_jobs(jobs_relation)
    find_solid_queue_jobs_within(jobs_relation).each(&:retry)
  end

  def retry_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).retry
  end

  def discard_all_jobs(jobs_relation)
    find_solid_queue_jobs_within(jobs_relation).each(&:discard)
  end

  def discard_job(job, jobs_relation)
    find_solid_queue_job!(job.job_id, jobs_relation).discard
  end

  def find_job(job_id, jobs_relation)
    if job = find_solid_queue_job(job_id, jobs_relation)
      deserialize_and_proxy_job job
    end
  end

  private
    def find_queue_by_name(queue_name)
      SolidQueue::Queue.find_by_name(queue_name)
    end

    def find_solid_queue_job!(job_id, jobs_relation)
      find_solid_queue_job(job_id, jobs_relation) or raise ActiveJob::Errors::JobNotFoundError.new(job_id)
    end

    def find_solid_queue_job(job_id, jobs_relation)
      find_solid_queue_jobs_within(jobs_relation).find_by(active_job_id: job_id)
    end

    def find_solid_queue_jobs_within(jobs_relation)
      JobFilter.new(jobs_relation).jobs
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

    class JobFilter
      def initialize(jobs_relation)
        @jobs_relation = jobs_relation
      end

      def jobs
        filter_by_status
          .then { |jobs| filter_by_queue(jobs) }
          .then { |jobs| filter_by_class(jobs) }
          .then { |jobs| limit(jobs) }
          .then { |jobs| offset(jobs) }
      end

      private
        attr_reader :jobs_relation

        delegate :queue_name, :status, :limit_value, :offset_value, :job_class_name, to: :jobs_relation

        def filter_by_status
          case status
          when :pending then SolidQueue::Job.joins(:ready_execution)
          when :failed  then SolidQueue::Job.joins(:failed_execution)
          else               SolidQueue::Job.all
          end
        end

        def filter_by_queue(jobs)
          queue_name.present? ? jobs.where(queue_name: queue_name) : jobs
        end

        def filter_by_class(jobs)
          job_class_name.present? ? jobs.where(class_name: job_class_name) : jobs
        end

        def limit(jobs)
          limit_value.present? ? jobs.limit(limit_value) : jobs
        end

        def offset(jobs)
          offset_value.present? ? jobs.offset(offset_value) : jobs
        end
    end
end
