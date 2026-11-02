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

  def formatted_duration(duration)
    total_ms = (duration * 1000).round
    days, rest = total_ms.divmod(86_400_000)
    hours, rest = rest.divmod(3_600_000)
    minutes, ms = rest.divmod(60_000)
    seconds = format("%.3f", ms / 1000.0).sub(/\.?0+\z/, "")

    parts = []
    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{seconds}s" if ms > 0 || parts.empty?
    parts.join(" ")
  end
end
