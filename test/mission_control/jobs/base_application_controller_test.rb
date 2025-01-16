require "test_helper"

class MissionControl::Jobs::BaseApplicationControllerTest < ActiveSupport::TestCase
  test "engine's ApplicationController inherits from host's ApplicationController by default" do
    assert MissionControl::Jobs::ApplicationController < ApplicationController
  end

  test "engine's ApplicationController inherits from configured base_controller_class" do
    assert MissionControl::Jobs::ApplicationController < MyApplicationController
  end
end
