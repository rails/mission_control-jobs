# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"

ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "mocha/minitest"

require "debug"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_paths.first + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require_relative "active_job/queue_adapters/adapter_testing"
Dir[File.join(__dir__, "support", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "active_job", "queue_adapters", "adapter_testing", "*.rb")].each { |file| require file }

ENV["FORK_PER_JOB"] = "false" # Disable forking when dispatching resque jobs

class ActiveSupport::TestCase
  include JobsHelper, JobQueuesHelper, QueriesHelper, ThreadHelper

  setup do
    @original_applications = MissionControl::Jobs.applications
    reset_executions_for_job_test_classes
    delete_adapters_data
    ActiveJob::Base.current_queue_adapter = nil
    reset_configured_queues_for_job_classes
  end

  teardown do
    MissionControl::Jobs.applications = @original_applications
  end

  private
    def reset_executions_for_job_test_classes
      ApplicationJob.descendants.including(ApplicationJob).each { |klass| klass.invocations&.clear }
    end

    def delete_adapters_data
      delete_resque_data
      delete_solid_queue_data
    end

    alias delete_all_jobs delete_adapters_data

    def delete_resque_data
      redis = root_resque_redis
      all_keys = redis.keys("test*")
      redis.del all_keys if all_keys.any?
    end

    def delete_solid_queue_data
      SolidQueue::Job.find_each(&:destroy)
      SolidQueue::Process.find_each(&:destroy)
      SolidQueue::RecurringTask.find_each(&:destroy)
      SolidQueue::Batch.find_each(&:destroy)
    end

    def root_resque_redis
      @root_resque_redis ||= Redis.new(host: "localhost", port: 6379)
    end

    def reset_configured_queues_for_job_classes
      ApplicationJob.descendants.including(ApplicationJob).each { |klass| klass.queue_as :default }
    end
end

class ActionDispatch::IntegrationTest
  ASYNC_TIMEOUT = 10.seconds
  ASYNC_POLLING_INTERVAL = 0.01
  SOLID_QUEUE_MODEL_NAMES = %w[ Batch BatchExecution BlockedExecution ClaimedExecution FailedExecution
    Job Pause Process ReadyExecution RecurringExecution RecurringTask ScheduledExecution Semaphore ]

  # Integration tests just use Solid Queue for now
  setup do
    MissionControl::Jobs.applications.add("integration-tests", { solid_queue: queue_adapter_for_test })

    @application = MissionControl::Jobs.applications["integration-tests"]
    @server = @application.servers[:solid_queue]
    @worker = SolidQueue::Worker.new(queues: "*", threads: 2, polling_interval: 0.01)

    recurring_task = { periodic_pause_job: { class: "PauseJob", schedule: "every second" } }
    @scheduler = SolidQueue::Scheduler.new(recurring_tasks: recurring_task)
  end

  teardown do
    @worker.stop
    @scheduler.stop
  end

  private
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::SolidQueueAdapter.new
    end

    def register_workers(count: 1)
      count.times { |i| SolidQueue::Process.register(kind: "Worker", pid: i, name: "worker-#{i}") }
    end

    # Solid Queue boots processes asynchronously, so the worker isn't registered when
    # +start+ returns. Wait for it before giving the jobs the requested processing time.
    def perform_enqueued_jobs_async(wait: 1.second)
      preload_solid_queue_schemas
      @worker.start
      wait_for_worker_registration
      sleep(wait)

      yield if block_given?
      @worker.stop
    end

    def schedule_recurring_tasks_async(wait: 1.second)
      @scheduler.start
      sleep(wait)

      yield if block_given?
      @scheduler.stop
    end

    # Transactional tests pin a single connection that the worker thread shares. Loading a
    # model's schema holds a class-level lock while it queries, so a model first touched
    # from the test thread while the worker holds that connection deadlocks the two. Warming
    # the schemas up before any worker starts keeps both threads off that path.
    def preload_solid_queue_schemas
      SOLID_QUEUE_MODEL_NAMES.each { |name| SolidQueue.const_get(name).load_schema }
    end

    def wait_for_worker_registration
      wait_until("the worker to register") { @worker.process_id.present? }
    end

    def wait_for_claimed_executions(count)
      wait_until("#{count} claimed executions") { SolidQueue::ClaimedExecution.count >= count }
    end

    def wait_until(condition, timeout: ASYNC_TIMEOUT)
      deadline = monotonic_now + timeout

      until yield
        raise "Timed out after #{timeout.inspect} waiting for #{condition}" if monotonic_now > deadline

        sleep ASYNC_POLLING_INTERVAL
      end
    end

    def monotonic_now
      ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
    end
end
