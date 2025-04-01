require_relative "../application_system_test_case"

class ListFailedJobsTest < ApplicationSystemTestCase
  setup do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    visit jobs_path(:failed)
  end

  test "view the failed jobs" do
    assert_equal 10, job_row_elements.length
    job_row_elements.each.with_index do |job_element, index|
      within job_element do
        assert_text "FailingJob"
        assert_text "#{index}"
      end
    end
  end

  test "filter by error message" do
    2.times { |index| FailingJob.perform_later("Ratelimit Error") }
    perform_enqueued_jobs

    visit jobs_path(:failed, filter: { error: "Ratelimit" })

    assert_equal 2, job_row_elements.length
    job_row_elements.each.with_index do |job_element, index|
      within job_element do
        assert_text "FailingJob"
        assert_text "Ratelimit Error" # Ensure the error message is displayed"
      end
    end
  end
end
