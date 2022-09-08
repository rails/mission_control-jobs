module ActiveJob::QueueAdapters::ResqueExt
  def initialize(redis = Resque.redis)
    super()
    @redis = redis
  end

  def activating(&block)
    original_redis = Resque.redis
    Resque.redis = @redis
    block.call
  ensure
    Resque.redis = original_redis
  end

  def queue_names
    Resque.queues
  end

  # Returns an array with the list of queues. Each queue is represented as a hash
  # with these attributes:
  #   {
  #    "name": "queue_name",
  #    "size": 1,
  #    active: true
  #   }
  def queues
    queues = queue_names
    active_statuses = []
    counts = []

    redis.multi do |multi|
      queues.each do |queue_name|
        active_statuses << multi.mget("pause:queue:#{queue_name}", "pause:all")
        counts << multi.llen("queue:#{queue_name}")
      end
    end

    queues.collect.with_index do |queue_name, index|
      { name: queue_name, active: active_statuses[index].value.compact.empty?, size: counts[index].value }
    end
  end

  def queue_size(queue_name)
    Resque.size queue_name
  end

  def clear_queue(queue_name)
    Resque.remove_queue(queue_name)
  end

  def pause_queue(queue_name)
    ResquePauseHelper.pause(queue_name)
  end

  def resume_queue(queue_name)
    ResquePauseHelper.unpause(queue_name)
  end

  def queue_paused?(queue_name)
    ResquePauseHelper.paused?(queue_name)
  end

  def jobs_count(jobs_relation)
    resque_jobs_for(jobs_relation).count
  end

  def fetch_jobs(jobs_relation)
    resque_jobs_for(jobs_relation).all
  end

  def support_class_name_filtering?
    false
  end

  def retry_all_jobs(jobs_relation)
    resque_jobs_for(jobs_relation).retry_all
  end

  def retry_job(job, jobs_relation)
    resque_jobs_for(jobs_relation).retry_job(job)
  end

  def discard_all_jobs(jobs_relation)
    resque_jobs_for(jobs_relation).discard_all
  end

  def discard_job(job, jobs_relation)
    resque_jobs_for(jobs_relation).discard_job(job)
  end

  def find_job(job_id, jobs_relation)
    resque_jobs_for(jobs_relation).find_job(job_id)
  end

  private
    attr_reader :redis

    def resque_jobs_for(jobs_relation)
      ResqueJobs.new(jobs_relation, redis: redis)
    end

    class ResqueJobs
      attr_reader :jobs_relation

      def initialize(jobs_relation, redis:)
        @jobs_relation = jobs_relation
        @redis = redis
      end

      def count
        if paginated?
          count_fetched_jobs # no direct way of counting jobs
        else
          direct_jobs_count
        end
      end

      def all
        fetch_resque_jobs.collect { |resque_job| deserialize_resque_job(resque_job) if resque_job.is_a?(Hash) }.compact
      end

      def retry_all
        jobs_relation.reverse.each do |job|
          retry_job(job)
        end
      end

      def retry_job(job)
        resque_requeue_and_remove(index_for!(job))
      end

      def discard_all
        if jobs_relation.failed? && targeting_all_jobs?
          clear_failed_queue
        else
          discard_all_one_by_one
        end
      end

      def discard_job(job)
        job_index = index_for!(job) # We want to resolve this outside the redis transaction

        redis.multi do |multi|
          multi.lset(queue_redis_key, job_index, SENTINEL)
          multi.lrem(queue_redis_key, 1, SENTINEL)
        end
      end

      def find_job(job_id)
        jobs_by_id[job_id]
      end

      private
        attr_reader :redis

        SENTINEL = "" # See +Resque::Datastore#remove_from_failed_queue+

        def targeting_all_jobs?
          !paginated? && jobs_relation.job_class_name.blank?
        end

        def paginated?
          jobs_relation.offset_value > 0 || limit_value_provided?
        end

        def limit_value_provided?
          jobs_relation.limit_value.present? && jobs_relation.limit_value != ActiveJob::JobsRelation::ALL_JOBS_LIMIT
        end

        def fetch_resque_jobs
          if jobs_relation.failed?
            fetch_failed_resque_jobs
          else
            fetch_queue_resque_jobs
          end
        end

        def fetch_failed_resque_jobs
          Array.wrap(Resque::Failure.all(jobs_relation.offset_value, jobs_relation.limit_value))
        end

        def fetch_queue_resque_jobs
          unless jobs_relation.queue_name.present?
            raise ActiveJob::Errors::QueryError, "This adapter only supports fetching failed jobs when no queue name is provided"
          end
          Array.wrap(Resque.peek(jobs_relation.queue_name, jobs_relation.offset_value, jobs_relation.limit_value))
        end

        def deserialize_resque_job(resque_job_hash)
          args_hash = resque_job_hash.dig("payload", "args") || resque_job_hash.dig("args")
          ActiveJob::JobProxy.new(args_hash&.first).tap do |job|
            job.last_execution_error = execution_error_from_resque_job(resque_job_hash)
          end
        end

        def execution_error_from_resque_job(resque_job_hash)
          if resque_job_hash["exception"].present?
            ActiveJob::ExecutionError.new \
          error_class: resque_job_hash["exception"],
          message: resque_job_hash["error"],
          backtrace: resque_job_hash["backtrace"]
          end
        end

        def direct_jobs_count
          case jobs_relation.status
          when :pending
              pending_jobs_count
          when :failed
              failed_jobs_count
          else
              raise ActiveJob::Errors::QueryError, "Status not supported: #{status}"
          end
        end

        def pending_jobs_count
          Resque.queue_sizes.inject(0) do |sum, (queue_name, queue_size)|
            if jobs_relation.queue_name.blank? || jobs_relation.queue_name == queue_name
              sum + queue_size
            else
              sum
            end
          end
        end

        def failed_jobs_count
          Resque.data_store.num_failed
        end

        def count_fetched_jobs
          all.size
        end

        def index_for(job)
          job_indexes_by_job_id[job.job_id]
        end

        def index_for!(job)
          index_for(job) or raise ActiveJob::Errors::JobNotFoundError.new(job)
        end

        def queue_redis_key
          jobs_relation.failed? ? "failed" : "queue:#{jobs_relation.queue_name}"
        end

        def clear_failed_queue
          Resque::Failure.clear("failed")
        end

        def discard_all_one_by_one
          jobs_relation.reverse.each do |job|
            discard_job(job)
          end
        end

        def resque_requeue_and_remove(job_index)
          Resque::Failure.requeue(job_index)
          Resque::Failure.remove(job_index)
        end

        def job_indexes_by_job_id
          @job_indexes_by_job_id ||= all_without_pagination_enumerator.collect.with_index { |job, index| [ job.job_id, index ] }.to_h
        end

        def jobs_by_id
          @jobs_by_id ||= all_without_pagination_enumerator.index_by(&:job_id)
        end

        # Returns an enumerator that loops through all the jobs in the relation, without
        # taking limit/offset into consideration. Internally, it will paginate jobs in batches.
        def all_without_pagination_enumerator
          from = 0
          Enumerator.new do |enumerator|
            begin
              current_page = jobs_relation.with_all_job_classes.offset(from).limit(jobs_relation.default_page_size)
              jobs = self.class.new(current_page, redis: redis).all
              jobs.each { |job| enumerator << job }
              from += jobs_relation.default_page_size
            end until jobs.empty?
          end
        end
    end
end
