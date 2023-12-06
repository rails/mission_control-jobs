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
        queue_adapter.queues.collect do |queue|
          ActiveJob::Queue.new(queue[:name], size: queue[:size], active: queue[:active], queue_adapter: queue_adapter)
        end.compact
      end
  end

  def queue
    self.class.queues[queue_name]
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
