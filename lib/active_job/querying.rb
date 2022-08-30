module ActiveJob::Querying
  extend ActiveSupport::Concern

  included do
    # ActiveJob will use pagination internally when fetching relations of jobs. This
    # parameter sets the max amount of jobs to fetch in each data store query.
    class_attribute :default_page_size, default: 1000
  end

  class_methods do
    # Returns the list of queues.
    #
    # See +ActiveJob::Queues+
    def queues
      ActiveJob::Queues.new(fetch_queues)
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

  # Top-level query methods added to `ActiveJob`
  module Root
    def queues
      ActiveJob::Base.queues
    end

    def jobs
      ActiveJob::Base.jobs
    end
  end
end
