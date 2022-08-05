require "active_job/queues"
require "active_job/queue_adapters/resque_ext"
require "active_job/queue"

module MissionControl
  module Jobs
    class Engine < ::Rails::Engine
      isolate_namespace MissionControl::Jobs

      initializer "active_job.extensions" do
        ActiveSupport.on_load :active_job do
          ActiveJob::Base.include ActiveJob::Queues
          ActiveJob::QueueAdapters::ResqueAdapter.include ActiveJob::QueueAdapters::ResqueExt
        end
      end
    end
  end
end
