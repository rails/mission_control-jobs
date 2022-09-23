require "mission_control/jobs/version"
require "mission_control/jobs/engine"

require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.expand_path("..", __dir__))
loader.setup

module MissionControl
  module Jobs
    mattr_accessor :applications, default: MissionControl::Jobs::Applications.new
    mattr_accessor :base_controller_class, default: "::ApplicationController"
    mattr_accessor :delay_between_bulk_operation_batches, default: 0
    mattr_accessor :logger, default: ActiveSupport::Logger.new(nil)
  end
end
