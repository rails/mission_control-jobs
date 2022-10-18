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
    resque_jobs_for(jobs_relation).discard(job)
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

      delegate :default_page_size, to: :jobs_relation

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
        @all ||= fetch_resque_jobs.collect.with_index { |resque_job, index| deserialize_resque_job(resque_job, index) if resque_job.is_a?(Hash) }.compact
      end

      def retry_all
        if use_batches?
          retry_all_in_batches
        else
          retry_jobs(jobs_relation.to_a.reverse)
        end
      end

      def retry_job(job)
        # Not named just +retry+ because it collides with reserved Ruby keyword.
        resque_requeue_and_discard(job)
      end

      def discard_all
        if jobs_relation.failed? && targeting_all_jobs?
          clear_failed_queue
        else
          discard_all_one_by_one
        end
      end

      def discard(job)
        redis.multi do |multi|
          multi.lset(queue_redis_key, job.position, SENTINEL)
          multi.lrem(queue_redis_key, 1, SENTINEL)
        end
      rescue Redis::CommandError => error
        handle_resque_job_error(job, error)
      end

      def find_job(job_id)
        jobs_by_id[job_id]
      end

      private
        attr_reader :redis

        SENTINEL = "" # See +Resque::Datastore#remove_from_failed_queue+

        # Redis transactions severely speed up operations, specially when the network latency is high.
        # We limit the transaction size because large batches can result in redis timeout errors.
        MAX_REDIS_TRANSACTION_SIZE = 100

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

        def deserialize_resque_job(resque_job_hash, index)
          args_hash = resque_job_hash.dig("payload", "args") || resque_job_hash.dig("args")
          ActiveJob::JobProxy.new(args_hash&.first).tap do |job|
            job.last_execution_error = execution_error_from_resque_job(resque_job_hash)
            job.raw_data = resque_job_hash
            job.position = jobs_relation.offset_value + index
            job.failed_at = resque_job_hash["failed_at"]&.to_datetime
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

        def queue_redis_key
          jobs_relation.failed? ? "failed" : "queue:#{jobs_relation.queue_name}"
        end

        def clear_failed_queue
          Resque::Failure.clear("failed")
        end

        def retry_jobs(jobs)
          in_transactional_jobs_batches(jobs) do |jobs_batch|
            jobs_batch.each { |job| retry_job(job) }
          end
        end

        def in_transactional_jobs_batches(jobs)
          jobs.each_slice(MAX_REDIS_TRANSACTION_SIZE) do |jobs_batch|
            redis.multi do |multi|
              yield jobs_batch
            end
          end
        end

        def use_batches?
          !jobs_relation.limit_value_provided? && jobs_relation.count > default_page_size
        end

        def retry_all_in_batches
          jobs_relation.in_batches(order: :desc, &:retry_all)
        end

        def resque_requeue_and_discard(job)
          requeue(job)
          discard(job)
        end

        def requeue(job)
          resque_job = job.raw_data
          resque_job["retried_at"] = Time.now.strftime("%Y/%m/%d %H:%M:%S")

          redis.lset(queue_redis_key, job.position, resque_job)
          Resque::Job.create(resque_job["queue"], resque_job["payload"]["class"], *resque_job["payload"]["args"])
        rescue Redis::CommandError => error
          handle_resque_job_error(job, error)
        end

        def discard_all_one_by_one
          if use_batches?
            discard_all_in_batches
          else
            discard_jobs(jobs_relation.to_a.reverse)
          end
        end

        def discard_jobs(jobs)
          in_transactional_jobs_batches(jobs) do |jobs_batch|
            jobs_batch.each { |job| discard(job) }
          end
        end

        def discard_all_in_batches
          jobs_relation.in_batches(order: :desc, &:discard_all)
        end

        def jobs_by_id
          @jobs_by_id ||= all.index_by(&:job_id)
        end

        def all_ignoring_filters
          @all_ignoring_filters ||= jobs_relation.with_all_job_classes.to_a
        end

        def handle_resque_job_error(job, error)
          if error.message =~/no such key/i
            raise ActiveJob::Errors::JobNotFoundError.new(job)
          else
            raise error
          end
        end
    end
end
