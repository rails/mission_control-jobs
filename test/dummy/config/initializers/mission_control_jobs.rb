require "resque"

root_redis = Redis::Namespace.new "#{Rails.env}", redis: Redis.new(host: "localhost", port: 6379, thread_safe: true)
Resque.redis = root_redis

SERVERS_BY_APP = {
  BC3: %w[ ashburn chicago ],
  HEY: %w[ us-east-1 ]
}

def redis_connection_for(parent_redis, app, server)
  redis = Redis.new(host: "localhost", port: 6379, thread_safe: true)
  Redis::Namespace.new "#{app}:#{server}", redis: parent_redis
end

SERVERS_BY_APP.each do |app, servers|
  queue_adapters_by_name = servers.collect do |server|
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new(redis_connection_for(root_redis, app, server))
    [ server, queue_adapter ]
  end.to_h

  MissionControl::Jobs.applications.add(app, queue_adapters_by_name)
end

puts "AFTER INITIALIZER: #{  Resque.redis.instance_variable_get("@redis").inspect}"
