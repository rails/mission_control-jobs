class MissionControl::Jobs::FailedJobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  helper_method :current_page

  def index
    @job_classes = ApplicationJob.jobs.failed.job_classes
    @jobs_count = filtered_failed_jobs.count # Capturing to save redis queries, which can be expensive with remote resque hosts
    @jobs = paginated(filtered_failed_jobs)
  end

  private
    PAGE_SIZE = 10

    def paginated(jobs_relation)
      jobs_relation.limit(PAGE_SIZE).offset((current_page - 1) * PAGE_SIZE)
    end

    def current_page
      if page_param
        page_param.to_i
      else
        1
      end
    end

    def page_param
      params[:page]
    end
end
