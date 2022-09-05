# Set and access +Resque.redis+ in a thread-safe way.
module Resque::ThreadSafeRedis
  thread_mattr_accessor :thread_resque_instance

  delegate :redis, :redis=, to: "Resque::ThreadSafeRedis.resque_instance"
  alias :data_store :redis # Override original alias

  def self.resque_instance
    # Not using +default:+ to set the default because it only applies
    # to the main thread.
    self.thread_resque_instance ||= ResqueInstance.new
  end

  # +Resque+ is a module that extends itself. We leverage this trait to create different
  # redis instances and reuse the actual `#redis=` and `#redis` accessors logic with
  # different data stores.
  class ResqueInstance
    include Resque
  end
end
