require_relative "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  include UIHelper

  include MissionControl::Jobs::Engine.routes.url_helpers
end

Capybara.configure do |config|
  config.server = :puma, { Silent: true, Threads: "10:50" }
end
