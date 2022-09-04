require_relative "../application_system_test_case"

class ListJobsTest < ApplicationSystemTestCase
  setup do
    DummyJob.queue_as :queue_1
    10.times { |index| DummyJob.perform_later(index) }

    visit application_queues_path
  end

  test "view the jobs in a queue" do
    click_on "queue_1"

    assert_equal 10, job_row_elements.length
    job_row_elements.each.with_index do |job_element, index|
      within job_element do
        assert_text "DummyJob"
        assert_text "#{index}"
      end
    end
  end
end
