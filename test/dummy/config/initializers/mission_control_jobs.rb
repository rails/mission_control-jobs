require "resque"
require "resque_pause_helper"

require "solid_queue"

Resque.redis = Redis::Namespace.new "#{Rails.env}", redis: Redis.new(host: "localhost", port: 6379)

SERVERS_BY_APP = {
  BC4: %w[ resque_ashburn resque_chicago ],
  HEY: %w[ resque queue queue_alternative ]
}

def redis_connection_for(app, server)
  redis_namespace = Redis::Namespace.new "#{app}:#{server}", redis: Resque.redis.instance_variable_get("@redis")
  Resque::DataStore.new redis_namespace
end

SERVERS_BY_APP.each do |app, servers|
  queue_adapters_by_name = servers.collect do |server|
    queue_adapter = if server.start_with?("resque")
      ActiveJob::QueueAdapters::ResqueAdapter.new(redis_connection_for(app, server))
    else
      ActiveJob::QueueAdapters::SolidQueueAdapter.new(server)
    end

    [ server, queue_adapter ]
  end.to_h

  MissionControl::Jobs.applications.add(app, queue_adapters_by_name)
end
