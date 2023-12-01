require_relative "../application_system_test_case"

class ListQueuesTest < ApplicationSystemTestCase
  setup do
    create_queues *10.times.collect { |index| "queue_#{index}" }
  end

  test "list queues sorted by name" do
    visit queues_path

    assert_equal 10, queue_row_elements.length
    queue_row_elements.each.with_index do |queue_element, index|
      within queue_element do
        assert_text "queue_#{index}"
      end
    end
  end

  test "list queues sorted by name and filtered by prefix" do
    with_queue_name_prefix do
      visit queues_path

      assert_equal 1, queue_row_elements.length
      within queue_row_elements.first do
        assert_text "queue_1"
      end
    end
  end

  private
    def with_queue_name_prefix(&block)
      previous_prefix, ActiveJob::Base.queue_name_prefix = ActiveJob::Base.queue_name_prefix, "queue_1"
      yield
    ensure
      ActiveJob::Base.queue_name_prefix = previous_prefix
    end
end
