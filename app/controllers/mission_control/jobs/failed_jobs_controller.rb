class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  def index
    @jobs = ApplicationJob.jobs.failed
  end
end
