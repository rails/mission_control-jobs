require "test_helper"

class MissionControl::Jobs::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    FailingJob.perform_later
    perform_enqueued_jobs_async
    2.times { DummyJob.perform_later }
  end

  test "shows counts for every status supported by the current adapter" do
    get mission_control_jobs.application_dashboard_url(@application)

    assert_response :ok
    assert_select "h1", "Jobs overview"
    assert_select "link[href*='mission_control/jobs/dashboard']"
    assert_select ".dashboard-metric", ActiveJob::JobsRelation::STATUSES.size
    assert_select "[data-dashboard-target='count'][data-status='pending']", text: "2"
    assert_select "[data-dashboard-target='count'][data-status='failed']", text: "1"
  end

  test "returns an adapter-independent JSON snapshot" do
    get mission_control_jobs.application_dashboard_url(@application, format: :json)

    assert_response :ok
    snapshot = response.parsed_body

    assert_match(/\A\d{4}-\d{2}-\d{2}T/, snapshot.fetch("recorded_at"))
    assert_equal({ "value" => 2, "exact" => true }, snapshot.dig("counts", "pending"))
    assert_equal({ "value" => 1, "exact" => true }, snapshot.dig("counts", "failed"))
    assert_equal ActiveJob::JobsRelation::STATUSES.map(&:to_s).sort, snapshot.fetch("counts").keys.sort
  end
end
