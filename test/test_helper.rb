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
  include JobsHelper, JobQueuesHelper, ThreadHelper

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
    end

    def root_resque_redis
      @root_resque_redis ||= Redis.new(host: "localhost", port: 6379, thread_safe: true)
    end

    def reset_configured_queues_for_job_classes
      ApplicationJob.descendants.including(ApplicationJob).each { |klass| klass.queue_as :default }
    end
end

class ActionDispatch::IntegrationTest
  # Integration tests just use Solid Queue for now
  setup do
    MissionControl::Jobs.applications.add("integration-tests", { solid_queue: queue_adapter_for_test })

    @application = MissionControl::Jobs.applications["integration-tests"]
    @server = @application.servers[:solid_queue]
    @worker = SolidQueue::Worker.new(queues: "*", threads: 2, polling_interval: 0.01)

    recurring_task = { periodic_pause_job: { class: "PauseJob", schedule: "every second" } }
    @dispatcher = SolidQueue::Dispatcher.new(recurring_tasks: recurring_task)
  end

  teardown do
    @worker.stop
    @dispatcher.stop
  end

  private
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::SolidQueueAdapter.new
    end

    def register_workers(count: 1)
      count.times { |i| SolidQueue::Process.register(kind: "Worker", pid: i) }
    end

    def perform_enqueued_jobs_async(wait: 1.second)
      @worker.start
      sleep(wait)

      yield if block_given?
      @worker.stop
    end

    def dispatch_jobs_async(wait: 1.second)
      @dispatcher.start
      sleep(wait)

      yield if block_given?
      @dispatcher.stop
    end
end
