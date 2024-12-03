require_relative "../application_system_test_case"

class DiscardQueueJobsTest < ApplicationSystemTestCase
  setup do
    DummyJob.queue_as :queue_1
    10.times { |index| DummyJob.perform_later("dummy-arg-#{index}") }

    visit queues_path
  end

  test "discard all jobs" do
    click_on "queue_1"

    assert_equal 10, job_row_elements.length

    accept_confirm do
      click_on "Discard all"
    end
  end
end
