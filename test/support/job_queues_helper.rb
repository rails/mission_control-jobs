module JobQueuesHelper
  extend ActiveSupport::Concern

  included do
    class_attribute :jobs_adapter
  end

  def DynamicQueueJob(queue_name)
    Class.new(ApplicationJob) do
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
