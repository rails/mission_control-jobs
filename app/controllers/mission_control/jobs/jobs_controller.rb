class MissionControl::Jobs::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped, MissionControl::Jobs::JobFilters

  skip_before_action :set_job, only: :index

  def index
    @job_class_names = jobs_with_status.job_class_names
    @queue_names = ApplicationJob.queues.map(&:name)

    @jobs_page = MissionControl::Jobs::Page.new(filtered_jobs_with_status, page: params[:page].to_i)
    @jobs_count = @jobs_page.total_count
  end

  def show
  end

  private
    def jobs_relation
      filtered_jobs
    end

    def filtered_jobs_with_status
      filtered_jobs.with_status(jobs_status)
    end

    def jobs_with_status
      ApplicationJob.jobs.with_status(jobs_status)
    end

    def filtered_jobs
      ApplicationJob.jobs.where(**@job_filters)
    end

    helper_method :jobs_status

    def jobs_status
      params[:status].presence&.inquiry
    end
end
