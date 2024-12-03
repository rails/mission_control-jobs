module MissionControl::Jobs::DatesHelper
  def time_distance_in_words_with_title(time)
    tag.span time_ago_in_words_with_default_options(time), title: "Since #{time.to_fs(:long)}"
  end

  def bidirectional_time_distance_in_words_with_title(time)
    time_distance = if time.past?
      "#{time_ago_in_words_with_default_options(time)} ago"
    else
      "in #{time_ago_in_words_with_default_options(time)}"
    end

    tag.span time_distance, title: time.to_fs(:long)
  end

  def time_ago_in_words_with_default_options(time)
    time_ago_in_words(time, include_seconds: true, locale: :en)
  end
end
