require "test_helper"

class MissionControl::Jobs::Queues::BulkDiscardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DummyJob.queue_as :queue_1
    3.times { |index| DummyJob.perform_later("job-#{index}") }
  end

  test "discard all pending jobs in a queue" do
    assert_equal 3, ActiveJob.queues[:queue_1].size

    post mission_control_jobs.application_queue_bulk_discards_url(@application, :queue_1)
    assert_redirected_to mission_control_jobs.application_queue_url(@application, "queue_1")
    assert_equal "Discarded 3 pending jobs", flash[:notice]
    assert_nil ActiveJob.queues[:queue_1]
  end

  test "discard all pending jobs when the queue has a single job" do
    ActiveJob.queues[:queue_1].jobs.discard_all
    DummyJob.perform_later("only-job")

    post mission_control_jobs.application_queue_bulk_discards_url(@application, :queue_1)
    assert_redirected_to mission_control_jobs.application_queue_url(@application, "queue_1")
    assert_equal "Discarded 1 pending job", flash[:notice]
    assert_nil ActiveJob.queues[:queue_1]
  end

  test "discard all pending jobs when the queue does not exist" do
    post mission_control_jobs.application_queue_bulk_discards_url(@application, :missing_queue)
    assert_redirected_to mission_control_jobs.root_url
    assert_equal "Queue 'missing_queue' not found", flash[:alert]
  end
end
