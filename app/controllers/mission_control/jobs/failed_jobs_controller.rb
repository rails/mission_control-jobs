class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  before_action :set_job, only: %i[ show ]

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @jobs_page = MissionControl::Jobs::Page.new(filtered_failed_jobs, page: params[:page].to_i)
    @jobs_count = @jobs_page.total_count
  end

  def show
  end

  private
    def set_job
      @job = ActiveJob.jobs.failed.find_by_id(params[:id])
    end
end
