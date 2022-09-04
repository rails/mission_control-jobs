class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  def index
    @jobs = ApplicationJob.jobs.failed
  end
end
