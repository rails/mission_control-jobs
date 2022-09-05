module ThreadHelper
  def sleep_to_force_race_condition
    sleep rand / 10.0 # 0.0Xs delays to minimize active delays while ensuring race conditions
  end
end
