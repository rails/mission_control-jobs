require_relative "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium_chrome_headless, screen_size: [ 1200, 1000 ]

  include UIHelper

  include MissionControl::Jobs::Engine.routes.url_helpers

  def run
    # Activate default job server so that setup data before any navigation
    # happens is loaded there.
    default_job_server.activating do
      super
    end
  end

  # UI tests just use Resque for now
  def perform_enqueued_jobs
    worker = Resque::Worker.new("*")
    # worker.work(0.0)
  end
end

Capybara.configure do |config|
  config.server = :puma, { Silent: true, Threads: "10:50" }
end
