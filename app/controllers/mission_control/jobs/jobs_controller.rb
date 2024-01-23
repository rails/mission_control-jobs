class MissionControl::Jobs::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped, MissionControl::Jobs::JobFilters

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @queue_names = ApplicationJob.queues.map(&:name)
    @jobs_page = MissionControl::Jobs::Page.new(filtered_failed_jobs, page: params[:page].to_i)
    @jobs_count = @jobs_page.total_count
  end

  def show
  end

  private
    def jobs_relation
      ApplicationJob.jobs.failed
    end
end
