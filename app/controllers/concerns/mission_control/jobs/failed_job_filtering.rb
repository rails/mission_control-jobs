module MissionControl::Jobs::FailedJobFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_job_class_filter
  end

  private
    def set_job_class_filter
      @job_class_filter = params.dig(:filter, :job_class)
    end

    def filtered_failed_jobs
      ApplicationJob.jobs.failed.where(job_class: @job_class_filter)
    end
end
