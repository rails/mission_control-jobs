require "zeitwerk"
class_loader = Zeitwerk::Loader.for_gem
class_loader.setup

require "mission_control/jobs/version"
require "mission_control/jobs/engine"

# TODO: Using Zeitwerk should prevent having to require these files, but it's not
#   working for active_job classes referred from the engine. In any case, temporary
#   problem since we will upstream all these extensions.
require "active_job/querying"
require "active_job/queue_adapters/resque_ext"
require "active_job/queue"
require "active_job/jobs_relation"
require "active_job/job_proxy"
require "active_job/execution_error"
require "active_job/errors/query_error"

module MissionControl
  module Jobs
  end
end
