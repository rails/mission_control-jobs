class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  def index
    @jobs = ActiveJob::Base.jobs.failed
  end
end
