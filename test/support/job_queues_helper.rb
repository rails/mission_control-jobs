module JobQueuesHelper
  extend ActiveSupport::Concern

  def DynamicQueueJob(queue_name)
    Class.new(ApplicationJob) do
      def self.name
        "DynamicQueueJob"
      end

      queue_as queue_name

      def perform
      end
    end
  end

  def create_queues(*names)
    names.each do |name|
      DynamicQueueJob(name).perform_later
    end
  end
end
