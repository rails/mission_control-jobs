module MissionControl::Jobs::JobsHelper
  def job_title(job)
    job.class_name
  end

  def job_arguments(job)
    renderable_job_arguments_for(job).join(", ")
  end

  def failed_jobs_count
    ActiveJob.jobs.failed.count
  end

  def failed_job_error(job)
    "#{job.last_execution_error.error_class}: #{job.last_execution_error.message}"
  end

  def failed_job_backtrace(job)
    job.last_execution_error.backtrace.join("\n")
  end

  private
    def renderable_job_arguments_for(job)
      ActiveJob::Arguments.deserialize(job.serialized_arguments).collect do |argument|
        case argument
        when ActiveRecord::Base
            argument.to_gid.uri.to_s
        else
            argument
        end
      end
    end
end
