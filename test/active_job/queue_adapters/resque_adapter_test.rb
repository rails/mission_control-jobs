require "test_helper"

class ActiveJob::QueueAdapters::ResqueAdapterTest < ActiveSupport::TestCase
  setup do
    @old_data_store = Resque.redis
  end

  teardown do
    Resque.redis = @old_data_store
  end

  test "create a new adapter with the default resque redis instance" do
    assert_no_changes -> { Resque.redis } do
      ActiveJob::QueueAdapters::ResqueAdapter.new
    end
  end

  test "activate configured redis instance on creation" do
    current_redis = current_resque_redis
    new_redis = create_redis "new_redis"

    assert_changes -> { current_resque_redis }, from: current_redis, to: new_redis do
      ActiveJob::QueueAdapters::ResqueAdapter.new(new_redis)
    end
  end

  test "activate a different redis instance" do
    old_redis = create_redis "old_redis"
    new_redis = create_redis "new_redis"
    adapter = ActiveJob::QueueAdapters::ResqueAdapter.new(new_redis)
    Resque.redis = old_redis

    assert_changes -> { current_resque_redis }, from: old_redis, to: new_redis do
      adapter.activate
    end
  end

  private
    def current_resque_redis
      Resque.redis.instance_variable_get("@redis")
    end

    def create_redis(name)
      redis = Redis.new(host: "localhost", port: 6379, thread_safe: true)
      Redis::Namespace.new "#{name}", redis: redis
    end
end
