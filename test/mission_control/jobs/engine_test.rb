require "test_helper"

class MissionControl::Jobs::EngineTest < ActiveSupport::TestCase
  test "applies configured default_page_size" do
    assert_equal 50, ActiveJob::Base.default_page_size
    assert_equal 50, ActiveJob.jobs.default_page_size
  end
end
