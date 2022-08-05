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

  def assert_queues(*expected_names)
    queues = ApplicationJob.queues

    assert_equal expected_names.length, queues.length
    expected_names.each.with_index do |expected_name, index|
      assert_equal expected_name, queues[index].name
    end
  end
end
