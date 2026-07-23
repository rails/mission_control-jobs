require "test_helper"

class MissionControl::Jobs::BatchesControllerTest < ActionDispatch::IntegrationTest
  # File-local job so no shared job class gets its queue adapter mutated
  class BatchedJob < ActiveJob::Base
    self.queue_adapter = :solid_queue
    queue_as :default

    def perform(*); end
  end

  teardown do
    @server.activating do
      SolidQueue::Job.destroy_all
      SolidQueue::Batch.destroy_all
    end
  end

  test "get batch list" do
    create_batch(description: "Nightly imports")

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "Nightly imports"
    assert_select "span.tag", "enqueued"
  end

  test "get batch details and pending job list" do
    batch = create_batch(description: "Nightly imports", jobs: 2)

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "h1", /Batch #{batch.id}/
    assert_select "h2", "2 pending jobs"
    assert_select "tr.job", 2
  end

  test "batch progress reflects finished jobs" do
    batch = create_batch(jobs: 4)
    @server.activating do
      SolidQueue::Job.where(batch_id: batch.id).order(:id).first.finished!
    end

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "td", /1 completed, 0 failed, 3 pending of 4 total/
  end

  test "redirect to batches list when batch doesn't exist" do
    get mission_control_jobs.application_batch_url(@application, 987654)
    assert_redirected_to mission_control_jobs.application_batches_url(@application)

    follow_redirect!

    assert_select "article.is-danger", /Batch with id '987654' not found/
  end

  private
    def create_batch(description: nil, jobs: 1)
      @server.activating do
        SolidQueue::Batch.enqueue(description: description) do
          jobs.times { |i| BatchedJob.perform_later(i) }
        end
      end
    end
end
