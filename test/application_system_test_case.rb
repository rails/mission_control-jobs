require_relative "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  include UIHelper

  include MissionControl::Jobs::Engine.routes.url_helpers

  # UI tests just use Resque for now
  def perform_enqueued_jobs
    worker = Resque::Worker.new("*")
    worker.work(0.0)
  end
end

Capybara.configure do |config|
  config.server = :puma, { Silent: true, Threads: "10:50" }
end
