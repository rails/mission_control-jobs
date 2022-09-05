module ResqueHelper
  extend ActiveSupport::Concern

  included do
    setup do
      @old_data_store = Resque.redis
    end

    teardown do
      Resque.redis = @old_data_store
    end
  end

  private
    def original_resque_redis
      redis_from_resque_data_store @old_data_store
    end

    def current_resque_redis
      redis_from_resque_data_store Resque.redis
    end

    def redis_from_resque_data_store(data_store)
      data_store.instance_variable_get("@redis")
    end

    def create_resque_redis(name)
      Redis::Namespace.new "resque:#{name}", redis: @old_data_store
    end
end
