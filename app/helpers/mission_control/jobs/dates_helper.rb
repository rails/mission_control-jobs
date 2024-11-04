module MissionControl::Jobs::DatesHelper
  def formatted_time(time)
    time.in_time_zone.strftime("%Y-%m-%d %H:%M:%S.%3N %Z")
  end
end
