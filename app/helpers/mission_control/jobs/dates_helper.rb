module MissionControl::Jobs::DatesHelper
  def formatted_time(time)
    time.strftime("%Y-%m-%d %H:%M:%S.%3N")
  end
end
