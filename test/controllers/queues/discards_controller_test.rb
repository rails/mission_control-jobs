require "test_helper"

class MissionControl::Jobs::Queues::DiscardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DummyJob.queue_as :queue_1
    @kept_job = DummyJob.perform_later("kept-job")
    @job = DummyJob.perform_later("pending-job")
  end

  test "discard a single pending job in a queue" do
    assert_equal 2, ActiveJob.queues[:queue_1].size

    post mission_control_jobs.application_queue_job_discard_url(@application, :queue_1, @job.job_id)
    assert_redirected_to mission_control_jobs.application_queue_url(@application, "queue_1")
    assert_equal "Discarded job with id #{@job.job_id}", flash[:notice]

    remaining_jobs = ActiveJob.queues[:queue_1].jobs.to_a
    assert_equal 1, remaining_jobs.size
    assert_equal @kept_job.job_id, remaining_jobs.first.job_id
  end

  test "discard a pending job with an invalid id" do
    post mission_control_jobs.application_queue_job_discard_url(@application, :queue_1, "unknown_id")
    assert_redirected_to mission_control_jobs.application_queue_url(@application, :queue_1)
    assert_match(/Job with id 'unknown_id' not found/, flash[:alert])
    assert_equal 2, ActiveJob.queues[:queue_1].reload.size
  end

  test "discard a pending job when the queue does not exist" do
    post mission_control_jobs.application_queue_job_discard_url(@application, :missing_queue, @job.job_id)
    assert_redirected_to mission_control_jobs.root_url
    assert_equal "Queue 'missing_queue' not found", flash[:alert]
  end

  test "does not discard finished jobs through the queue discard endpoint" do
    ActiveJob.queues[:queue_1].jobs.discard_all

    finished_job = DummyJob.perform_later("finished-job")
    perform_enqueued_jobs_async

    pending_job = DummyJob.perform_later("still-pending")
    assert_equal 1, ActiveJob.queues[:queue_1].size

    post mission_control_jobs.application_queue_job_discard_url(@application, :queue_1, finished_job.job_id)
    assert_redirected_to mission_control_jobs.application_queue_url(@application, :queue_1)
    assert_equal "Only pending jobs can be discarded from a queue", flash[:alert]
    assert_equal [ pending_job.job_id ], ActiveJob.queues[:queue_1].reload.jobs.map(&:job_id)
  end
end
