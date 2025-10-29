require "test_helper"

class MissionControl::Jobs::InterfaceHelperTest < ActionView::TestCase
  include MissionControl::Jobs::InterfaceHelper

  test "jobs_count_for returns formatted count for finite numbers" do
    mock_with_status = Minitest::Mock.new
    mock_count = Minitest::Mock.new

    ActiveJob.stub :jobs, mock_with_status do
      mock_with_status.expect :with_status, mock_count, [ :failed ]
      mock_count.expect :count, 1000

      result = jobs_count_for(:failed)
      assert_equal "1K", result

      mock_with_status.verify
      mock_count.verify
    end
  end

  test "jobs_count_for returns formatted count with plus suffix for infinite count" do
    mock_with_status = Minitest::Mock.new
    mock_count = Minitest::Mock.new

    ActiveJob.stub :jobs, mock_with_status do
      mock_with_status.expect :with_status, mock_count, [ :failed ]
      mock_count.expect :count, Float::INFINITY

      result = jobs_count_for(:failed)
      expected = number_to_human(MissionControl::Jobs.count_limit,
                                format: "%n%u",
                                units: { thousand: "K", million: "M", billion: "B", trillion: "T", quadrillion: "Q" }) + "+"

      assert_equal expected, result

      mock_with_status.verify
      mock_count.verify
    end
  end

  test "jobs_count_for works with different statuses" do
    statuses = [ :pending, :finished, :failed, :blocked, :scheduled, :in_progress ]

    statuses.each do |status|
      mock_with_status = Minitest::Mock.new
      mock_count = Minitest::Mock.new

      ActiveJob.stub :jobs, mock_with_status do
        mock_with_status.expect :with_status, mock_count, [ status ]
        mock_count.expect :count, 1000

        result = jobs_count_for(status)
        assert_equal "1K", result

        mock_with_status.verify
        mock_count.verify
      end
    end
  end

  test "jobs_count_for handles zero count" do
    mock_with_status = Minitest::Mock.new
    mock_count = Minitest::Mock.new

    ActiveJob.stub :jobs, mock_with_status do
      mock_with_status.expect :with_status, mock_count, [ :pending ]
      mock_count.expect :count, 0

      result = jobs_count_for(:pending)
      assert_equal "0", result

      mock_with_status.verify
      mock_count.verify
    end
  end

  test "jobs_count_for handles small numbers without abbreviation" do
    mock_with_status = Minitest::Mock.new
    mock_count = Minitest::Mock.new

    ActiveJob.stub :jobs, mock_with_status do
      mock_with_status.expect :with_status, mock_count, [ :pending ]
      mock_count.expect :count, 500

      result = jobs_count_for(:pending)
      assert_equal "500", result

      mock_with_status.verify
      mock_count.verify
    end
  end

  test "jobs_count_for handles large numbers with proper formatting" do
    test_cases = [
      [ 1500, "1.5K" ],
      [ 2500000, "2.5M" ],
      [ 1000000000, "1B" ],
      [ 1000000000000, "1T" ],
      [ 1000000000000000, "1Q" ]
    ]

    test_cases.each do |count, expected|
      mock_with_status = Minitest::Mock.new
      mock_count = Minitest::Mock.new

      ActiveJob.stub :jobs, mock_with_status do
        mock_with_status.expect :with_status, mock_count, [ :finished ]
        mock_count.expect :count, count

        result = jobs_count_for(:finished)
        assert_equal expected, result

        mock_with_status.verify
        mock_count.verify
      end
    end
  end
end
