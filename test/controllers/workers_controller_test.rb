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

      assert_includes response.body, "worker #{worker.id}"
      assert_includes response.body, "PauseJob"
      assert_includes response.body, "my-hostname-123"
    end
  end

  test "get worker details" do
    perform_enqueued_jobs_async(wait: 0) do
      worker = @server.workers_relation.first

      get mission_control_jobs.application_worker_url(@application, worker.id)
      assert_response :ok

      assert_includes response.body, "Worker #{worker.id}"
      assert_includes response.body, "Running 2 jobs"
    end
  end
end
