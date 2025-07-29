require "test_helper"

class MissionControl::JobArgumentFilterTest < ActiveSupport::TestCase
  test "filter_arguments" do
    arguments = [
      "deliver",
      {
        email_address: "jorge@37signals.com",
        profile: { name: "Jorge Manrubia" },
        message: "Hello!"
      }
    ]
    @previous_filter_arguments, MissionControl::Jobs.filter_arguments = MissionControl::Jobs.filter_arguments, %w[ email_address message ]

    filtered = MissionControl::JobArgumentFilter.filter_arguments(arguments)

    assert_equal "deliver", filtered[0]
    assert_equal({ email_address: "[FILTERED]", profile: { name: "Jorge Manrubia" }, message: "[FILTERED]" }, filtered[1])
  ensure
    MissionControl::Jobs.filter_arguments = @previous_filter_arguments
  end

  test "filter_argument_hash" do
    argument = {
      email_address: "jorge@37signals.com",
      message: "Hello!"
    }
    @previous_filter_arguments, MissionControl::Jobs.filter_arguments = MissionControl::Jobs.filter_arguments, %w[ message ]

    filtered = MissionControl::JobArgumentFilter.filter_argument_hash(argument)

    assert_equal({ email_address: "jorge@37signals.com", message: "[FILTERED]" }, filtered)
  ensure
    MissionControl::Jobs.filter_arguments = @previous_filter_arguments
  end
end
