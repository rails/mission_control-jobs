require_relative "../application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    FailingJob.perform_later
    perform_enqueued_jobs
    2.times { DummyJob.perform_later }
  end

  test "shows and refreshes the statuses supported by Resque" do
    visit dashboard_path

    assert_text "Jobs overview"
    assert_selector ".dashboard-metric", count: 2
    assert_selector "[data-dashboard-target='count'][data-status='pending']", text: "2"
    assert_selector "[data-dashboard-target='count'][data-status='failed']", text: "1"
    assert_text "Live"

    DummyJob.perform_later

    assert_selector "[data-dashboard-target='count'][data-status='pending']", text: "3", wait: 7
  end
end
