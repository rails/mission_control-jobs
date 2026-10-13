require "test_helper"

class MissionControl::Jobs::DatesHelperTest < ActionView::TestCase
  tests MissionControl::Jobs::DatesHelper

  setup do
    @time = Time.utc(2024, 10, 8, 12, 30)
  end

  test "time titles use the application time zone" do
    Time.use_zone("Buenos Aires") do
      assert_title "Since October 08, 2024 09:30", time_distance_in_words_with_title(@time)
      assert_title "Since October 08, 2024 09:30", time_distance_in_words_with_title(@time.to_datetime)
      assert_title "October 08, 2024 09:30", bidirectional_time_distance_in_words_with_title(@time)
    end
  end

  private
    def assert_title(expected, html)
      assert_equal expected, Nokogiri::HTML5.fragment(html).at("span")["title"]
    end
end
