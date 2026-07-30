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

  test "batch list is paginated" do
    12.times { |i| create_batch(description: "Batch #{i}") }

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok
    assert_select "tr.batch", 10
    assert_select "nav[aria-label=pagination]"

    get mission_control_jobs.application_batches_url(@application, page: 2)
    assert_response :ok
    assert_select "tr.batch", 2
  end

  test "batch list filters by finished, unfinished, and failed" do
    create_batch(description: "Still going")
    finished = create_batch(description: "All done")
    failed = create_batch(description: "Went wrong")
    @server.activating do
      SolidQueue::Job.where(batch_id: finished.id).each { |job| finish(job) }
      SolidQueue::Job.where(batch_id: failed.id).each { |job| fail_job(job, RuntimeError.new("boom")) }
    end

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok
    assert_select "tr.batch", 2 # a failed batch has also finished

    get mission_control_jobs.application_batches_url(@application, batches_status: "unfinished")
    assert_response :ok
    assert_select "tr.batch", 1
    assert_select "td", "Still going"

    get mission_control_jobs.application_batches_url(@application, batches_status: "failed")
    assert_response :ok
    assert_select "tr.batch", 1
    assert_select "td", "Went wrong"

    get mission_control_jobs.application_batches_url(@application)
    assert_select "tr.batch", 3
  end

  test "batch list pagination preserves the status filter" do
    12.times { create_batch }

    get mission_control_jobs.application_batches_url(@application, batches_status: "unfinished")
    assert_response :ok
    assert_select "tr.batch", 10
    assert_select "nav[aria-label=pagination] a[href*=?]", "batches_status=unfinished"
  end

  test "batch list shows an empty notice for a status filter without matches" do
    create_batch(description: "Still going")

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok
    assert_select "tr.batch", 0
    assert_select "div", text: "No finished batches found"
  end

  test "batch list shows an empty notice when there are no batches" do
    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 0
    assert_select "div", text: "There are no batches"
  end

  test "get batch details and pending job list" do
    batch = create_batch(description: "Nightly imports", jobs: 2)

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "h1", /Batch #{batch.id}/
    assert_select "h2", "2 pending jobs"
    assert_select "tr.job", 2
  end

  test "batch details expose each unfinished job status separately" do
    batch = create_batch_with_unfinished_statuses

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "td a", "1 pending"
    assert_select "td a", "1 in progress"
    assert_select "td a", "1 blocked"
    assert_select "td a", "1 scheduled"

    %w[ pending in_progress blocked scheduled ].each do |status|
      get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: status)
      assert_response :ok

      assert_select "h2", "1 #{status.dasherize} job"
      assert_select "tr.job", 1
    end
  end

  test "scheduled-only batch shows its scheduled jobs by default" do
    batch = create_batch(jobs: 2, wait: 1.hour)

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "h2", "2 scheduled jobs"
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

  test "pagination preserves the selected jobs status" do
    batch = create_batch(jobs: 3)
    @server.activating do
      SolidQueue::Job.where(batch_id: batch.id).find_each { |job| finish(job) }
    end

    stub_const(MissionControl::Jobs::Page, :DEFAULT_PAGE_SIZE, 2) do
      get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: :finished)
      assert_response :ok

      next_page_url = css_select("a.pagination-next").find { |link| link.text == "Next page" }["href"]
      assert_includes next_page_url, "jobs_status=finished"

      get next_page_url
      assert_response :ok

      assert_select "h2", "3 finished jobs"
      assert_select "tr.job", 1
    end
  end

  test "redirect to batches list when batch doesn't exist" do
    get mission_control_jobs.application_batch_url(@application, 987654)
    assert_redirected_to mission_control_jobs.application_batches_url(@application)

    follow_redirect!

    assert_select "article.is-danger", /Batch with id '987654' not found/
  end

  private
    def create_batch(description: nil, jobs: 1, wait: nil)
      @server.activating do
        SolidQueue::Batch.enqueue(description: description) do
          jobs.times do |i|
            wait ? BatchedJob.set(wait: wait).perform_later(i) : BatchedJob.perform_later(i)
          end
        end
      end
    end

    def create_batch_with_unfinished_statuses
      @server.activating do
        batch = SolidQueue::Batch.enqueue do
          3.times { |i| BatchedJob.perform_later(i) }
          BatchedJob.set(wait: 1.hour).perform_later(3)
        end

        claimed_job_id, blocked_job_id = SolidQueue::ReadyExecution.where(job_id: batch.jobs.ids).order(:job_id).limit(2).pluck(:job_id)
        SolidQueue::ReadyExecution.where(job_id: [ claimed_job_id, blocked_job_id ]).delete_all

        SolidQueue::ClaimedExecution.insert_all!([ { job_id: claimed_job_id, process_id: nil, created_at: Time.current } ])
        SolidQueue::Job.where(id: blocked_job_id).update_all(concurrency_key: "batch-key")
        SolidQueue::BlockedExecution.insert_all!([ {
          job_id: blocked_job_id,
          queue_name: "default",
          priority: 0,
          concurrency_key: "batch-key",
          expires_at: 1.hour.from_now,
          created_at: Time.current
        } ])

        batch
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
