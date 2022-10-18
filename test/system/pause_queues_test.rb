require_relative "../application_system_test_case"

class PauseQueuesTest < ApplicationSystemTestCase
  setup do
    create_queues "queue_1", "queue_2"

    visit queues_path
  end

  test "pause and resume a queue from the list of queues" do
    within_queue_row "queue_2" do
      assert_no_text "Resume"
      click_on "Pause"
      assert_text "Resume"

      click_on "Resume"
      assert_no_text "Resume"
      assert_text "Pause"
    end
  end

  test "pause and resume a queue in the details screen" do
    click_on "queue_2"

    assert_no_text "Resume"
    click_on "Pause"
    assert_text "Resume"

    click_on "Resume"
    assert_no_text "Resume"
    assert_text "Pause"
  end
end
