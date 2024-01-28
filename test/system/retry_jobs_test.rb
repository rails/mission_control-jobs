require_relative "../application_system_test_case"

class RetryJobsTest < ApplicationSystemTestCase
  setup do
    4.times { |index| FailingJob.set(queue: "queue_1").perform_later(index) }
    3.times { |index| FailingReloadedJob.set(queue: "queue_2").perform_later(4 + index) }
    2.times { |index| FailingJob.set(queue: "queue_2").perform_later(7 + index) }
    perform_enqueued_jobs

    visit jobs_path(:failed)
  end

  test "retry all failed jobs" do
    assert_equal 9, job_row_elements.length

    click_on "Retry all"

    assert_text "Retried 9 jobs"
    assert_empty job_row_elements
  end

  test "retry a single job" do
    assert_equal 9, job_row_elements.length
    expected_job_id = ApplicationJob.jobs.failed[2].job_id

    within_job_row "2" do
      click_on "Retry"
    end

    assert_text "Retried job with id #{expected_job_id}"

    assert_equal 8, job_row_elements.length
  end

  test "retry a selection of filtered jobs by class name" do
    assert_equal 9, job_row_elements.length

    fill_in "filter[job_class_name]", with: "FailingJob"
    assert_text /6 jobs found/i

    click_on "Retry selection"
    assert_text /retried 6 jobs/i
    assert_equal 3, job_row_elements.length
  end

  test "retry a selection of filtered jobs by queue name" do
    assert_equal 9, job_row_elements.length

    fill_in "filter[queue_name]", with: "queue_1"
    assert_text /4 jobs found/i

    click_on "Retry selection"
    assert_text /retried 4 jobs/i
    assert_equal 5, job_row_elements.length
  end

  test "retry a job from its details screen" do
    assert_equal 9, job_row_elements.length
    failed_job = ApplicationJob.jobs.failed[2]
    visit job_path(failed_job.job_id)

    click_on "Retry"

    assert_text "Retried job with id #{failed_job.job_id}"
    assert_equal 8, job_row_elements.length
  end
end
