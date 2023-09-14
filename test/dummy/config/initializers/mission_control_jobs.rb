require "resque"
require "resque_pause_helper"

require "solid_queue"

Resque.redis = Redis::Namespace.new "#{Rails.env}", redis: Redis.new(host: "localhost", port: 6379, thread_safe: true)

SERVERS_BY_APP = {
  BC3: %w[ ashburn chicago ],
  HEY: %w[ us-east-1 ]
}

def redis_connection_for(app, server)
  redis_namespace = Redis::Namespace.new "#{app}:#{server}", redis: Resque.redis.instance_variable_get("@redis")
  Resque::DataStore.new redis_namespace
end

SERVERS_BY_APP.each do |app, servers|
  queue_adapters_by_name = servers.collect do |server|
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new(redis_connection_for(app, server))
    [ server, queue_adapter ]
  end.to_h

  MissionControl::Jobs.applications.add(app, queue_adapters_by_name)
end
