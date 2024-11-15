require "test_helper"

class MissionControl::Jobs::InternalApi::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = mission_control_jobs.application_internal_api_dashboard_index_url(@application)
    MissionControl::SolidQueueJob.destroy_all
    MissionControl::SolidQueueFailedExecution.destroy_all
  end

  test "index returns valid JSON structure" do
    get @base_url
    assert_response :ok

    response_data = JSON.parse(response.body)
    assert response_data.key?("uptime")
    assert response_data.key?("total")

    %w[label pending failed finished].each do |key|
      assert response_data["uptime"].key?(key)
    end

    %w[failed pending scheduled in_progress finished].each do |key|
      assert response_data["total"].key?(key)
    end
  end

  test "index correctly formats numbers with delimiters" do
    ActiveJob::Base.queue_adapter = :test
  
    1234.times { FailingJob.perform_later }
    1678.times { DummyJob.perform_later }

    await_perform_all_enqueued_jobs

    get @base_url
    assert_response :ok

    response_data = JSON.parse(response.body)

    assert_equal "1,234", response_data["total"]["failed"]
    assert_equal "1,678", response_data["total"]["finished"]
  end  

  test "index calculates uptime data correctly" do
    job = MissionControl::SolidQueueJob.create!(queue_name: 'default', class_name: 'DummyJob')
    MissionControl::SolidQueueFailedExecution.create!(job_id: job.id, created_at: 2.seconds.ago)
    MissionControl::SolidQueueJob.create!(queue_name: 'default', class_name: 'DummyJob', finished_at: 3.seconds.ago)

    get @base_url, params: { uptime: 5 }
    assert_response :ok

    response_data = JSON.parse(response.body)
    uptime = response_data["uptime"]

    assert_equal 1, uptime["failed"]
    assert_equal 1, uptime["finished"]
  end

  test "index handles custom uptime parameter" do
    job = MissionControl::SolidQueueJob.create!(queue_name: 'default', class_name: 'DummyJob', finished_at: Time.now)
    MissionControl::SolidQueueFailedExecution.create!(job_id: job.id, created_at: 10.seconds.ago)

    get @base_url, params: { uptime: 15 }
    assert_response :ok

    response_data = JSON.parse(response.body)
    uptime = response_data["uptime"]

    assert_equal 0, uptime["pending"]
    assert_equal 1, uptime["failed"]
    assert_equal 1, uptime["finished"]
  end  
end
