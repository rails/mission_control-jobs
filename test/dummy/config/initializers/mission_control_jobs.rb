SERVERS_BY_APP = {
  BC3: %w[ ashburn chicago ],
  HEY: %w[ us-east-1 ]
}

def redis_connection_for(app, server)
  redis = Redis.new(host: "localhost", port: 6379, thread_safe: true)
  Redis::Namespace.new "#{app}:#{server}", redis: redis
end

SERVERS_BY_APP.each do |app, servers|
  queue_adapters_by_name = servers.collect do |server|
    queue_adapter = ActiveJob::QueueAdapters::ResqueAdapter.new(redis_connection_for(app, server))
    [ server, queue_adapter ]
  end.to_h

  MissionControl::Jobs.applications.add(app, queue_adapters_by_name)
end
