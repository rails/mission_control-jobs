class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  def index
    @jobs = ApplicationJob.jobs.failed
    @jobs_count = @jobs.count # Capturing because used in several places and queries are expensive for redis instances in remote datacenters.
  end
end
