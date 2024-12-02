module MissionControl::Jobs::DatesHelper
  def time_ago_in_words_with_title(time)
    tag.span time_ago_in_words(time), title: time.to_fs(:long)
  end

  def time_distance_in_words_with_title(time)
    tag.span distance_of_time_in_words_to_now(time, include_seconds: true), title: "Since #{time.to_fs(:long)}"
  end

  def bidirectional_time_distance_in_words_with_title(time)
    time_distance = if time.past?
      "#{distance_of_time_in_words_to_now(time, include_seconds: true)} ago"
    else
      "in #{distance_of_time_in_words_to_now(time, include_seconds: true)}"
    end

    tag.span time_distance, title: time.to_fs(:long)
  end

  def formatted_time(time)
    time.in_time_zone.strftime("%Y-%m-%d %H:%M:%S.%3N %Z")
  end
end
