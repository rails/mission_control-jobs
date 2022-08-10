require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.expand_path("..", __dir__))
loader.setup

require "mission_control/jobs/version"
require "mission_control/jobs/engine"

module MissionControl
  module Jobs
  end
end
