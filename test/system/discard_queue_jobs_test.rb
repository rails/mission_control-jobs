require_relative "../application_system_test_case"

class DiscardQueueJobsTest < ApplicationSystemTestCase
  setup do
    DummyJob.queue_as :queue_1
    10.times { |index| DummyJob.perform_later("job-#{index}") }

    visit queues_path
  end

  test "discard all pending jobs in a queue from the list of queues" do
    within_queue_row "queue_1" do
      assert_text "10"

      accept_confirm do
        click_on "Discard all pending jobs"
      end
    end

    assert_text "Discarded 10 pending jobs"

    within_queue_row "queue_1" do
      assert_text "0"
      assert_button "Discard all pending jobs", disabled: true
    end
  end

  test "discard all pending jobs in a queue from the details screen" do
    click_on "queue_1"

    assert_equal 10, job_row_elements.length

    accept_confirm do
      click_on "Discard all pending jobs"
    end

    assert_text "Discarded 10 pending jobs"
    assert_text /queue is empty/i
  end

  test "discard all pending jobs button is disabled when the queue is empty" do
    perform_enqueued_jobs
    click_on "queue_1"

    assert_button "Discard all pending jobs", disabled: true
  end

  test "discard a single pending job from the queue details screen" do
    click_on "queue_1"

    assert_equal 10, job_row_elements.length
    expected_job_id = ActiveJob.queues["queue_1"].jobs.find { |job| job.serialized_arguments == [ "job-3" ] }.job_id

    within_job_row("job-3") do
      accept_confirm do
        click_on "Discard"
      end
    end

    assert_text "Discarded job with id #{expected_job_id}"
    assert_equal 9, job_row_elements.length
    assert_no_text "job-3"
  end
end
