require "test_helper"

class MissionControl::Jobs::ArgumentsFilterTest < ActiveSupport::TestCase
  test "apply_to array" do
    arguments = [
      "deliver",
      {
        email_address: "jorge@37signals.com",
        profile: { name: "Jorge Manrubia" },
        message: "Hello!"
      }
    ]
    filtered = MissionControl::Jobs::ArgumentsFilter.new(%w[ email_address message ]).apply_to(arguments)

    assert_equal "deliver", filtered[0]
    assert_equal({ email_address: "[FILTERED]", profile: { name: "Jorge Manrubia" }, message: "[FILTERED]" }, filtered[1])
  end

  test "apply_to hash" do
    argument = {
      email_address: "jorge@37signals.com",
      message: "Hello!"
    }
    filtered = MissionControl::Jobs::ArgumentsFilter.new(%w[ message ]).apply_to(argument)

    assert_equal({ email_address: "jorge@37signals.com", message: "[FILTERED]" }, filtered)
  end
end
