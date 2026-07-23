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
      finish SolidQueue::Job.where(batch_id: batch.id).order(:id).first
    end

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "td a", "1 completed"
    assert_select "td a", "3 pending"
    assert_select "td", /of 4 total/
  end

  test "failed batch shows its failed jobs with error details" do
    batch = create_batch(description: "Doomed", jobs: 2)
    @server.activating do
      jobs = SolidQueue::Job.where(batch_id: batch.id).order(:id).to_a
      fail_job jobs.first, RuntimeError.new("boom went the job")
      finish jobs.second
    end

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "span.tag", "failed"
    assert_select "h2", "1 failed job"
    assert_select "tr.job", 1
    assert_select "td", /boom went the job/
    assert_select "td a", "1 failed"
  end

  test "jobs_status param switches the job list" do
    batch = create_batch(jobs: 3)
    @server.activating do
      finish SolidQueue::Job.where(batch_id: batch.id).order(:id).first
    end

    get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: :finished)
    assert_response :ok

    assert_select "h2", "1 finished job"
    assert_select "tr.job", 1
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

    # Mirror the real worker flow: the execution is claimed away before the job resolves
    def finish(job)
      SolidQueue::ReadyExecution.where(job_id: job.id).destroy_all
      job.finished!
    end

    def fail_job(job, error)
      SolidQueue::ReadyExecution.where(job_id: job.id).destroy_all
      job.failed_with(error)
    end
end
