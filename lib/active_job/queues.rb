module ActiveJob::Queues
  extend ActiveSupport::Concern

  class_methods do
    # Returns the queues indexed by name. The hash supports both strings
    # and symbols for accessing the queues.
    #
    #   ApplicationJob.queues[:some_queue] #=> <ActiveJob::Queue:0x000000010e302f00 @name="some_queue">
    def queues
      fetch_queues.index_by(&:name).with_indifferent_access
    end

    private
      def fetch_queues
        queue_adapter.queue_names.collect do |queue_name|
          ActiveJob::Queue.new(queue_name, queue_adapter: queue_adapter)
        end
      end
  end
end
