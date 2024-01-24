class MissionControl::Jobs::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped, MissionControl::Jobs::JobFilters

  def index
    @job_class_names = jobs_with_status.job_class_names
    @queue_names = ApplicationJob.queues.map(&:name)

    @jobs_page = MissionControl::Jobs::Page.new(filtered_jobs, page: params[:page].to_i)
    @jobs_count = @jobs_page.total_count
  end

  def show
  end

  private
    def jobs_relation
      ApplicationJob.jobs
    end

    def jobs_with_status
      jobs_relation.with_status(jobs_status)
    end

    def filtered_jobs
      jobs_with_status.where(**@job_filters)
    end

    helper_method :jobs_status

    def jobs_status
      params[:status].presence
    end
end
