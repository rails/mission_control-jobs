require_relative "../application_system_test_case"

class ShowFailedJobsTest < ApplicationSystemTestCase
  setup do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs
    visit jobs_path(:failed)
  end

  test "click on a failed job to see its details" do
    within_job_row /FailingJob\s*2/ do
      click_on "FailingJob"
    end

    assert_text /arguments\s*2/i
    assert_text /failing_job.rb/
  end

  test "click on a failed job error to see its error information" do
    within_job_row /FailingJob\s*2/ do
      click_on "RuntimeError: This always fails!"
    end

    assert_text /failing_job.rb/
  end

  test "show empty notice when no jobs" do
    ActiveJob.jobs.failed.discard_all
    visit jobs_path(:failed)
    assert_text /there are no failed jobs/i
  end
end
