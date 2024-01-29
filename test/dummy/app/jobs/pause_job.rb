class PauseJob < ApplicationJob
  def perform(time = 1)
    sleep(time)
  end
end
