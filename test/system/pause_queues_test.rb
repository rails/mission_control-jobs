require_relative "../application_system_test_case"

class PauseQueuesTest < ApplicationSystemTestCase
  setup do
    create_queues "queue_1", "queue_2"

    visit application_queues_path(@application)
  end

  test "pause and resume a queue" do
    within_queue_row "queue_2" do
      assert_no_text "Resume"
      click_on "Pause"
      assert_text "Resume"

      click_on "Resume"
      assert_no_text "Resume"
      assert_text "Pause"
    end
  end
end
