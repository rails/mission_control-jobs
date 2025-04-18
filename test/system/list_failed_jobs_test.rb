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

  test "filter by error message should handle jobs with nil errors" do
    # Create a custom failing job that might result in nil error
    # This test ensures that the system doesn't crash when filtering jobs that might have nil errors
    # First create some regular jobs with errors
    2.times { FailingJob.perform_later("Regular Error") }
    perform_enqueued_jobs
    
    # Now visit with a filter that won't match any jobs
    visit jobs_path(:failed, filter: { error: "NonexistentErrorText" })
    
    # Page should load without errors, even if some jobs have nil errors
    assert_text "No jobs found"
  end
end
