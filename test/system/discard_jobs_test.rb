require_relative "../application_system_test_case"

class DiscardJobsTest < ApplicationSystemTestCase
  setup do
    4.times { |index| FailingJob.set(queue: "queue_1").perform_later("failing-arg-#{index}") }
    3.times { |index| FailingReloadedJob.set(queue: "queue_2").perform_later("failing-reloaded-arg-#{4 + index}") }
    2.times { |index| FailingJob.set(queue: "queue_2").perform_later("failing-arg-#{7 + index}") }
    perform_enqueued_jobs

    visit jobs_path(:failed)
  end

  test "discard all failed jobs" do
    assert_equal 9, job_row_elements.length

    accept_confirm do
      click_on "Discard all"
    end

    assert_text "Discarded 9 jobs"
    assert_empty job_row_elements
  end

  test "discard a single job" do
    assert_equal 9, job_row_elements.length
    expected_job_id = ActiveJob.jobs.failed[2].job_id

    within_job_row "failing-arg-2" do
      accept_confirm do
        click_on "Discard"
      end
    end

    assert_text "Discarded job with id #{expected_job_id}"

    assert_equal 8, job_row_elements.length
  end

  test "discard a selection of filtered jobs by class name" do
    assert_equal 9, job_row_elements.length

    fill_in "filter[job_class_name]", with: "FailingReloadedJob"
    assert_text /3 jobs found/i

    accept_confirm do
      click_on "Discard selection"
    end

    assert_text /discarded 3 jobs/i
    assert_equal 6, job_row_elements.length
  end

  test "discard a selection of filtered jobs by queue name" do
    assert_equal 9, job_row_elements.length

    fill_in "filter[queue_name]", with: "queue_2"
    assert_text /5 jobs found/i

    accept_confirm do
      click_on "Discard selection"
    end

    assert_text /discarded 5 jobs/i
    assert_equal 4, job_row_elements.length
  end

  test "discard a job from its details screen" do
    assert_equal 9, job_row_elements.length
    failed_job = ActiveJob.jobs.failed[2]
    visit job_path(failed_job.job_id)

    accept_confirm do
      click_on "Discard"
    end

    assert_text "Discarded job with id #{failed_job.job_id}"
    assert_equal 8, job_row_elements.length
  end
end
