module MissionControl::Jobs::DatesHelper
  def time_ago_in_words_with_title(time)
    content_tag(:time, time_ago_in_words(time), title: time.to_fs(:long))
  end
end
