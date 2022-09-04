require "mission_control/jobs/version"
require "mission_control/jobs/engine"

require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

module MissionControl
  module Jobs
    class Engine < ::Rails::Engine
      isolate_namespace MissionControl::Jobs

      config.mission_control = ActiveSupport::OrderedOptions.new
      config.mission_control.jobs = ActiveSupport::OrderedOptions.new

      config.before_initialize do
        config.mission_control.jobs.applications = MissionControl::Jobs::Applications.new

        config.mission_control.jobs.each do |key, value|
          MissionControl::Jobs.public_send("#{key}=", value)
        end
      end

      initializer "mission_control-jobs.active_job.extensions" do
        ActiveSupport.on_load :active_job do
          include ActiveJob::Querying
          include ActiveJob::Executing
          ActiveJob.extend ActiveJob::Querying::Root
        end
      end

      config.before_initialize do
        ActiveJob::QueueAdapters::ResqueAdapter.prepend ActiveJob::QueueAdapters::ResqueExt
        Resque.extend Resque::ThreadSafeRedis
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
