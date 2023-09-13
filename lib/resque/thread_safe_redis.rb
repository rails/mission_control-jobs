# Set and access +Resque.redis+ in a thread-safe way.
module Resque::ThreadSafeRedis
  thread_mattr_accessor :thread_resque_override

  def self.resque_override
    self.thread_resque_override ||= ResqueOverride.new
  end

  def redis
    Resque::ThreadSafeRedis.resque_override.data_store_override || super
  end
  alias :data_store :redis

  def with_per_thread_redis_override(redis_instance, &block)
    Resque::ThreadSafeRedis.resque_override.enable_with(redis_instance, &block)
  end

  class ResqueOverride
    include Resque

    attr_accessor :data_store_override

    def enable_with(server, &block)
      previous_redis, previous_data_store_override = redis, data_store_override
      self.redis = server
      self.data_store_override = @data_store

      block.call
    ensure
      self.redis = previous_redis
      self.data_store_override = previous_data_store_override
    end
  end
end
