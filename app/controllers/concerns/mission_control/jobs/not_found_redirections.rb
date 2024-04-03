module MissionControl::Jobs::NotFoundRedirections
  extend ActiveSupport::Concern

  included do
    rescue_from(ActiveJob::Errors::JobNotFoundError) do |error|
      redirect_to best_location_for_job_relation(error.job_relation), alert: error.message
    end

    rescue_from(MissionControl::Jobs::Errors::ResourceNotFound) do |error|
      redirect_to best_location_for_resource_not_found_error(error), alert: error.message
    end
  end

  private
    def best_location_for_job_relation(job_relation)
      case
      when job_relation.failed?
        application_jobs_path(@application, :failed)
      when job_relation.queue_name.present?
        application_queue_path(@application, job_relation.queue_name)
      else
        root_path
      end
    end

    def best_location_for_resource_not_found_error(error)
      if error.message.match?(/recurring task/i)
        application_recurring_tasks_path(@application)
      else
        root_url
      end
    end
end
