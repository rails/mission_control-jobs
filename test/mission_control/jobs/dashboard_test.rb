require "test_helper"

class MissionControl::Jobs::DashboardTest < ActiveSupport::TestCase
  test "takes a snapshot through Active Job relations" do
    jobs = mock
    jobs.expects(:counts_by_status).with(statuses: %i[ pending failed ]).returns(pending: 12, failed: 3)

    travel_to Time.utc(2026, 8, 17, 12, 30, 45) do
      snapshot = MissionControl::Jobs::Dashboard.new(statuses: %i[ pending failed ], jobs: jobs).snapshot

      assert_equal "2026-08-17T12:30:45.000Z", snapshot[:recorded_at]
      assert_equal({ value: 12, exact: true }, snapshot[:counts][:pending])
      assert_equal({ value: 3, exact: true }, snapshot[:counts][:failed])
    end
  end

  test "marks adapter-limited counts as inexact" do
    jobs = mock
    jobs.expects(:counts_by_status).with(statuses: [ :pending ]).returns(pending: Float::INFINITY)

    snapshot = MissionControl::Jobs::Dashboard.new(statuses: [ :pending ], jobs: jobs).snapshot

    assert_equal({ value: nil, exact: false }, snapshot[:counts][:pending])
  end
end
