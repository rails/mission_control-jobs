require_relative "../application_system_test_case"

class RetryJobsTest < ApplicationSystemTestCase
  setup do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    visit failed_jobs_path
  end

  test "retry all failed jobs" do
    assert_equal 10, job_row_elements.length

    click_on "Retry all"

    assert_text "Retried 10 jobs"
    assert_empty job_row_elements
  end

  test "retry a single job" do
    assert_equal 10, job_row_elements.length
    expected_job_id = ApplicationJob.jobs.failed[2].job_id

    within_job_row "2" do
      click_on "Retry"
    end

    assert_text "Retried job with id #{expected_job_id}"

    assert_equal 9, job_row_elements.length
  end
end
