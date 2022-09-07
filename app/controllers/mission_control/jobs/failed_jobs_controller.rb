class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  def index
    @jobs = ApplicationJob.jobs.failed
    @jobs_count = @jobs.count # Capturing to save redis queries, which can be expensive with remote resque hosts.
  end
end
