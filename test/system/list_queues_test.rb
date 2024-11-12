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
end
