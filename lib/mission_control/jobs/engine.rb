require "mission_control/jobs/version"
require "mission_control/jobs/engine"

require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

module MissionControl
  module Jobs
    class Engine < ::Rails::Engine
      isolate_namespace MissionControl::Jobs

      initializer "active_job.extensions" do
        ActiveSupport.on_load :active_job do
          ActiveJob::Base.include ActiveJob::Querying
          ActiveJob::Base.include ActiveJob::Executing
          ActiveJob.extend ActiveJob::Querying::Root
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

      initializer "mission_control-jobs.assets" do |app|
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.precompile += %w[ mission_control_jobs_manifest ]
      end

      initializer "mission_control-jobs.importmap", before: "importmap" do |app|
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end
  end
end
