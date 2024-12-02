module MissionControl::Jobs::DatesHelper
  def time_distance_in_words_with_title(time)
    tag.span time_ago_in_words(time, include_seconds: true), title: "Since #{time.to_fs(:long)}"
  end

  def bidirectional_time_distance_in_words_with_title(time)
    time_distance = if time.past?
      "#{distance_of_time_in_words_to_now(time, include_seconds: true)} ago"
    else
      "in #{distance_of_time_in_words_to_now(time, include_seconds: true)}"
    end

    tag.span time_distance, title: time.to_fs(:long)
  end
end
