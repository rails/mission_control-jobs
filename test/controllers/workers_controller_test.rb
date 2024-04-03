require "test_helper"

class MissionControl::Jobs::WorkersControllerTest < ActionDispatch::IntegrationTest
  setup do
    2.times { PauseJob.perform_later }
    Socket.stubs(:gethostname).returns("my-hostname-123")
  end

  test "get workers" do
    perform_enqueued_jobs_async(wait: 0) do
      worker = @server.workers_relation.first
      get mission_control_jobs.application_workers_url(@application)

      assert_select "tr.worker", 1
      assert_select "tr.worker", /worker #{worker.id}\s+PID: \d+\s+my-hostname-123\s+PauseJob/
    end
  end

  test "paginate workers" do
    register_workers(count: 6)

    stub_const(MissionControl::Jobs::Page, :DEFAULT_PAGE_SIZE, 2) do
      get mission_control_jobs.application_workers_url(@application)
      assert_response :ok

      assert_select "tr.worker", 2
      assert_select "nav[aria-label=\"pagination\"]", /1 \/ 3/
    end
  end

  test "get worker details" do
    perform_enqueued_jobs_async(wait: 0) do
      worker = @server.workers_relation.first

      get mission_control_jobs.application_worker_url(@application, worker.id)
      assert_response :ok

      assert_select "h1", /Worker #{worker.id} — PID: \d+/
      assert_select "h2", "Running 2 jobs"
    end
  end
end
