require "test_helper"

class MissionControl::Jobs::BatchesControllerTest < ActionDispatch::IntegrationTest
  # Pinning a shared job class to an adapter would stop it inheriting the one
  # the adapter tests set, so batches get their own job class
  class BatchedJob < ActiveJob::Base
    self.queue_adapter = :solid_queue
    queue_as :default

    def perform(*); end
  end

  test "get batch list" do
    create_batch(description: "Older imports")
    create_batch(description: "Nightly imports")

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 2
    assert_select "span.tag", "enqueued"
    assert_select "li.is-active a", "Unfinished"
    assert_equal [ "Nightly imports", "Older imports" ], css_select("tr.batch td:nth-child(2)").collect { |cell| cell.text.strip }
  end

  test "get batch list when the server doesn't support batches" do
    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok
    assert_select "a", text: "Batches", count: 1

    @server.queue_adapter.stubs(:supports_batches?).returns(false)

    get mission_control_jobs.application_batches_url(@application)
    assert_redirected_to mission_control_jobs.root_url

    get mission_control_jobs.application_batch_url(@application, 987654)
    assert_redirected_to mission_control_jobs.root_url

    get mission_control_jobs.application_jobs_url(@application, :pending)
    assert_response :ok
    assert_select "a", text: "Batches", count: 0
  end

  test "get batch list when there are no batches" do
    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 0
    assert_select "li.is-active a", "Unfinished"
    assert_select "div", text: "No unfinished batches found"

    get mission_control_jobs.application_batches_url(@application, batches_status: "all")
    assert_response :ok

    assert_select "tr.batch", 0
    assert_select "div", text: "There are no batches"
  end

  test "paginate batches" do
    12.times { |i| create_batch(description: "Batch #{i}") }

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 10
    assert_select "nav[aria-label=\"pagination\"]", /1 \/ 2/
    assert_select "nav[aria-label=\"pagination\"] a[href*=?]", "batches_status=unfinished"
    assert_select "a.pagination-next", text: "↠", count: 1

    get mission_control_jobs.application_batches_url(@application, page: 2)
    assert_response :ok

    assert_select "tr.batch", 2
  end

  test "filter batches by status" do
    create_batch(description: "Still going")
    finished = create_batch(description: "All done")
    failed = create_batch(description: "Went wrong")
    SolidQueue::Job.where(batch_id: finished.id).each { |job| finish(job) }
    SolidQueue::Job.where(batch_id: failed.id).each { |job| fail_job(job, RuntimeError.new("boom")) }

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok

    assert_select "td", "All done"
    assert_select "td", "Went wrong"

    get mission_control_jobs.application_batches_url(@application, batches_status: "unfinished")
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "Still going"

    get mission_control_jobs.application_batches_url(@application, batches_status: "failed")
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "Went wrong"

    get mission_control_jobs.application_batches_url(@application, batches_status: "all")
    assert_response :ok

    assert_select "tr.batch", 3
  end

  test "get batch list defaulting to the unfinished batches" do
    create_batch(description: "Still going")
    finished = create_batch(description: "All done")
    SolidQueue::Job.where(batch_id: finished.id).each { |job| finish(job) }

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "Still going"

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "All done"
  end

  test "get batch list filtered by a status without matches" do
    create_batch(description: "Still going")

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok

    assert_select "tr.batch", 0
    assert_select "div", text: "No finished batches found"
  end

  test "paginate batches preserving the all population" do
    12.times { |i| create_batch(description: "Batch #{i}") }
    SolidQueue::Batch.order(:id).limit(3).each { |batch| SolidQueue::Job.where(batch_id: batch.id).each { |job| finish(job) } }

    get mission_control_jobs.application_batches_url(@application, batches_status: "all")
    assert_response :ok

    assert_select "tr.batch", 10

    next_page_url = css_select("a.pagination-next").find { |link| link.text == "Next page" }["href"]
    assert_includes next_page_url, "batches_status=all"

    get next_page_url
    assert_response :ok

    assert_select "li.is-active a", "All"
    assert_select "tr.batch", 2
  end

  test "count batches once per request" do
    12.times { create_batch }

    queries = capture_select_queries do
      get mission_control_jobs.application_batches_url(@application)
    end
    assert_response :ok

    count_queries = queries.grep(/\ASELECT COUNT\(\*\) FROM .*solid_queue_batches/i)
    assert_equal 1, count_queries.size, count_queries.join("\n\n")

    fetch_queries = queries.grep(/\ASELECT "?solid_queue_batches"?\.\* FROM/i)
    assert_equal 1, fetch_queries.size, fetch_queries.join("\n\n")
  end

  test "hide the jump-to-last link when the batches count is capped" do
    12.times { create_batch }
    original_limit = MissionControl::Jobs.internal_query_count_limit
    MissionControl::Jobs.internal_query_count_limit = 5

    get mission_control_jobs.application_batches_url(@application)
    assert_response :ok

    assert_select "nav[aria-label=\"pagination\"]", /1 \/ \.\.\./
    assert_select "a.pagination-next", text: "↠", count: 0
    assert_select "a.pagination-next", text: "Next page", count: 1
  ensure
    MissionControl::Jobs.internal_query_count_limit = original_limit
  end

  test "get batch details and pending job list" do
    batch = create_batch(description: "Nightly imports", jobs: 2)

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "h1", /Batch #{batch.id}/
    assert_select "h2", "2 pending jobs"
    assert_select "tr.job", 2
  end

  test "get batch details filtered by each unfinished job status" do
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

  test "get batch details listing only that batch's jobs" do
    batch = create_batch(jobs: 2)
    other_batch = create_batch(jobs: 2)
    BatchedJob.perform_later(99)
    finish SolidQueue::Job.where(batch_id: batch.id).order(:id).first
    SolidQueue::Job.where(batch_id: other_batch.id).each { |job| finish(job) }

    get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: :pending)
    assert_response :ok

    assert_select "h2", "1 pending job"
    assert_select "tr.job", 1

    get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: :finished)
    assert_response :ok

    assert_select "h2", "1 finished job"
    assert_select "tr.job", 1
  end

  test "get batch details for a completed batch" do
    batch = create_batch(jobs: 2)
    SolidQueue::Job.where(batch_id: batch.id).each { |job| finish(job) }

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "span.tag", "completed"
    assert_select "h2", "2 finished jobs"
    assert_select "tr.job", 2
  end

  test "get batch details filtered by job status" do
    batch = create_batch(jobs: 3)
    finish SolidQueue::Job.where(batch_id: batch.id).order(:id).first

    get mission_control_jobs.application_batch_url(@application, batch.id, jobs_status: :finished)
    assert_response :ok

    assert_select "h2", "1 finished job"
    assert_select "tr.job", 1
  end

  test "get batch details for a batch with only scheduled jobs" do
    batch = create_batch(jobs: 2, wait: 1.hour)

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "h2", "2 scheduled jobs"
    assert_select "tr.job", 2
  end

  test "get batch details with finished jobs" do
    batch = create_batch(jobs: 4)
    finish SolidQueue::Job.where(batch_id: batch.id).order(:id).first

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "td a", "1 completed"
    assert_select "td a", "3 pending"
    assert_select "td", /of 4 total/
  end

  test "get batch details for a failed batch" do
    batch = create_batch(description: "Doomed", jobs: 2)
    jobs = SolidQueue::Job.where(batch_id: batch.id).order(:id).to_a
    fail_job jobs.first, RuntimeError.new("boom went the job")
    finish jobs.second

    get mission_control_jobs.application_batch_url(@application, batch.id)
    assert_response :ok

    assert_select "span.tag", "failed"
    assert_select "h2", "1 failed job"
    assert_select "tr.job", 1
    assert_select "td", /boom went the job/
    assert_select "td a", "1 failed"
  end

  test "get batch list and details for a batch enqueued with no jobs" do
    SolidQueue::Batch.enqueue(description: "No work") { }

    get mission_control_jobs.application_batches_url(@application, batches_status: "finished")
    assert_response :ok

    assert_select "tr.batch", 1
    assert_select "td", "No work"
    assert_select "span.tag", "completed"

    get mission_control_jobs.application_batch_url(@application, SolidQueue::Batch.last.id)
    assert_response :ok

    assert_select "td", /of 0 total/
  end

  test "paginate batch jobs preserving the job status" do
    batch = create_batch(jobs: 3)
    SolidQueue::Job.where(batch_id: batch.id).find_each { |job| finish(job) }

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

  test "get job details for a batched job" do
    batch = create_batch(description: "Nightly imports")
    job = SolidQueue::Job.where(batch_id: batch.id).sole

    get mission_control_jobs.application_job_url(@application, job.active_job_id)
    assert_response :ok

    assert_select "th", "Part of"
    assert_select "td a[href=?]", mission_control_jobs.application_batch_path(@application, batch.id), text: "batch #{batch.id}"
  end

  test "get job details for an unbatched job" do
    job = BatchedJob.perform_later(1)

    get mission_control_jobs.application_job_url(@application, job.job_id)
    assert_response :ok

    assert_select "th", text: "Part of", count: 0
  end

  test "redirect to batches list when batch doesn't exist" do
    get mission_control_jobs.application_batch_url(@application, 987654)
    assert_redirected_to mission_control_jobs.application_batches_url(@application)

    follow_redirect!

    assert_select "article.is-danger", /Batch with id '987654' not found/
  end

  private
    def create_batch(description: nil, jobs: 1, wait: nil)
      SolidQueue::Batch.enqueue(description: description) do
        jobs.times do |i|
          wait ? BatchedJob.set(wait: wait).perform_later(i) : BatchedJob.perform_later(i)
        end
      end
    end

    def create_batch_with_unfinished_statuses
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

    def finish(job)
      SolidQueue::ReadyExecution.where(job_id: job.id).destroy_all
      job.finished!
    end

    def fail_job(job, error)
      SolidQueue::ReadyExecution.where(job_id: job.id).destroy_all
      job.failed_with(error)
    end
end
