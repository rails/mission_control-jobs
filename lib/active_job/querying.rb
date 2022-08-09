module ActiveJob::Querying
  extend ActiveSupport::Concern

  included do
    # ActiveJob will use pagination internally when fetching relations of jobs. This
    # parameter sets the max amount of jobs to fetch in each data store query.
    class_attribute :default_page_size, default: 1000

    # TODO: These should be moved to +ActiveJob::Core+ when upstreaming.
    attr_accessor :last_execution_error
    attr_reader :serialized_arguments
  end

  class_methods do
    # Returns the queues indexed by name. The hash supports both strings
    # and symbols for accessing the queues.
    #
    #   ApplicationJob.queues[:some_queue] #=> <ActiveJob::Queue:0x000000010e302f00 @name="some_queue">
    def queues
      fetch_queues.index_by(&:name).with_indifferent_access
    end

    def jobs
      ActiveJob::JobsRelation.new(queue_adapter: queue_adapter, default_page_size: default_page_size)
    end

    private
      def fetch_queues
        queue_adapter.queue_names.collect do |queue_name|
          ActiveJob::Queue.new(queue_name, queue_adapter: queue_adapter)
        end
      end
  end

  module Root
    def queues
      ActiveJob::Base.queues
    end

    def jobs
      ActiveJob::Base.jobs
    end
  end
end
