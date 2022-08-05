module ActiveJob::Queues
  extend ActiveSupport::Concern

  class_methods do
    def queues
      queue_adapter.queue_names.collect do |queue_name|
        ActiveJob::Queue.new(queue_name)
      end
    end
  end
end
