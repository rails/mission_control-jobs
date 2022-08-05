module ActiveJob::Queues
  extend ActiveSupport::Concern

  class_methods do
    def queues
      queue_adapter.queue_names.collect do |queue_name|
        ActiveJob::Queue.new(queue_name, queue_adapter: queue_adapter)
      end
    end

    def queue(name)
      queues.find { |queue| queue.name == name }
    end
  end
end
