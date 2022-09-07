class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @jobs = filtered_failed_jobs
    @jobs_count = @jobs.count # Capturing to save redis queries, which can be expensive with remote resque hosts
  end
end
