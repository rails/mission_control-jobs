require "test_helper"

class ActiveJob::JobArgumentFilterTest < ActiveSupport::TestCase
  setup do
    @application = MissionControl::Jobs::Application.new(name: "BC4")
    MissionControl::Jobs::Current.application = @application
  end

  test "filter_arguments" do
    arguments = [
      "deliver",
      {
        email_address: "jorge@37signals.com",
        profile: { name: "Jorge Manrubia" },
        message: "Hello!"
      }
    ]
    @application.filter_arguments = %i[ email_address message ]

    filtered = ActiveJob::JobArgumentFilter.filter_arguments(arguments)

    assert_equal "deliver", filtered[0]
    assert_equal({ email_address: "[FILTERED]", profile: { name: "Jorge Manrubia" }, message: "[FILTERED]" }, filtered[1])
  end

  test "filter_argument_hash" do
    argument = {
      email_address: "jorge@37signals.com",
      message: "Hello!"
    }
    filtered = ActiveJob::JobArgumentFilter.filter_argument_hash(argument)
    assert_equal({ email_address: "jorge@37signals.com", message: "Hello!" }, filtered)

    @application.filter_arguments = %i[ message ]
    filtered = ActiveJob::JobArgumentFilter.filter_argument_hash(argument)
    assert_equal({ email_address: "jorge@37signals.com", message: "[FILTERED]" }, filtered)
  end
end
