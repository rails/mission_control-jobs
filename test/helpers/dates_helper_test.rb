require "test_helper"

class MissionControl::Jobs::DatesHelperTest < ActionView::TestCase
  test "format durations below a minute with millisecond precision" do
    assert_equal "0s", formatted_duration(0)
    assert_equal "0.001s", formatted_duration(0.0012)
    assert_equal "1.5s", formatted_duration(1.5)
    assert_equal "59.999s", formatted_duration(59.9994)
  end

  test "format durations with minutes, hours and days" do
    assert_equal "1m", formatted_duration(60)
    assert_equal "1m 0.5s", formatted_duration(60.5)
    assert_equal "1h 2m 3.456s", formatted_duration(3723.456)
    assert_equal "2d 1h", formatted_duration(2 * 86_400 + 3600)
  end

  test "round up to the next unit" do
    assert_equal "1m", formatted_duration(59.9996)
  end
end
