require "mission_control/jobs/version"
require "mission_control/jobs/engine"

require "zeitwerk"
class_loader = Zeitwerk::Loader.for_gem
class_loader.setup

module MissionControl
  module Jobs
  end
end
