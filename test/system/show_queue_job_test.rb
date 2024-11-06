require_relative "../application_system_test_case"

class ShowQueueJobsTest < ApplicationSystemTestCase
  setup do
    DummyJob.queue_as :queue_1
    10.times { |index| DummyJob.perform_later("dummy-arg-#{index}") }

    visit queues_path
  end

  test "click on a queue job to see its details" do
    click_on "queue_1"

    within_job_row /dummy-arg-2/ do
      click_on "DummyJob"
    end

    assert_text /arguments\s*dummy-arg-2/i
  end
end
