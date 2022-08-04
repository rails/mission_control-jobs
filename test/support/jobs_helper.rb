module JobsHelper
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
end
