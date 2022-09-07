class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  before_action :set_job_class_filter, only: :index

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @jobs = filtered_failed_jobs
    @jobs_count = @jobs.count # Capturing to save redis queries, which can be expensive with remote resque hosts
  end

  private
    def set_job_class_filter
      @job_class_filter = params.dig(:filter, :job_class)
    end

    def filtered_failed_jobs
      ApplicationJob.jobs.failed.where(job_class: @job_class_filter)
    end
end
