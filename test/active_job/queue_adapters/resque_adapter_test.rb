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

    ActiveJob::QueueAdapters::ResqueAdapter.new(new_redis)

    assert_equal new_redis, current_resque_redis
    assert_not_equal current_redis, current_resque_redis
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
