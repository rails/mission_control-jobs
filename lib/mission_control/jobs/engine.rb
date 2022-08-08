require "active_job/querying"
require "active_job/queue_adapters/resque_ext"
require "active_job/queue"
require "active_job/jobs_relation"
require "active_job/execution_error"

module MissionControl
  module Jobs
    class Engine < ::Rails::Engine
      isolate_namespace MissionControl::Jobs

      initializer "active_job.extensions" do
        ActiveSupport.on_load :active_job do
          ActiveJob::Base.include ActiveJob::Querying
          ActiveJob::QueueAdapters::ResqueAdapter.include ActiveJob::QueueAdapters::ResqueExt
        end
      end

      initializer "mission_control-jobs.testing" do
        ActiveSupport.on_load(:active_support_test_case) do
          parallelize_setup do |worker|
            redis = Redis.new(host: "localhost", port: 6379, thread_safe: true)
            Resque.redis = Redis::Namespace.new "test-#{worker}", redis: redis
          end

          parallelize_teardown do
            delete_adapters_data
          end
        end
      end
    end
  end
end
