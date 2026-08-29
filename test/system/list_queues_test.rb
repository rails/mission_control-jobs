require_relative "../application_system_test_case"

class ListQueuesTest < ApplicationSystemTestCase
  setup do
    create_queues *10.times.collect { |index| "queue_#{index}" }
  end

  test "list queues sorted by name" do
    visit queues_path

    assert_text "10 pending jobs across 10 queues"

    assert_equal 10, queue_row_elements.length
    queue_row_elements.each.with_index do |queue_element, index|
      within queue_element do
        assert_text "queue_#{index}"
      end
    end
  end

  test "back to main app points to root path by default" do
    visit queues_path

    assert_equal "/", URI.parse(find_link("Back to main app")[:href]).path
  end

  test "back to main app points to configured override path" do
    original_back_to_main_app_path = MissionControl::Jobs.back_to_main_app_path
    MissionControl::Jobs.back_to_main_app_path = "/admin"

    visit queues_path

    assert_equal "/admin", URI.parse(find_link("Back to main app")[:href]).path
  ensure
    MissionControl::Jobs.back_to_main_app_path = original_back_to_main_app_path
  end
end
