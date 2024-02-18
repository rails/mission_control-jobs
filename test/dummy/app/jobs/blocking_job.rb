class BlockingJob < ApplicationJob
  limits_concurrency key: ->(*args) { "exclusive" }

  def perform(pause = nil)
    sleep(pause) if pause
  end
end
