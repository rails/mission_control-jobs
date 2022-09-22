class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @jobs_count = filtered_failed_jobs.count # Capturing to save redis queries, which can be expensive with remote resque hosts

    @jobs_page = MissionControl::Jobs::Page.new(filtered_failed_jobs, page: params[:page].to_i)
  end
end
