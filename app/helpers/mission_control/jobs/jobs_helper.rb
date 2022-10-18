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
      job.serialized_arguments.collect do |argument|
        as_renderable_argument(argument)
      end
    end

    def as_renderable_argument(argument)
      if argument.is_a?(Hash) && argument["_aj_globalid"]
        # don't deserialize as the class might not exist in the host app running the engine
        argument["_aj_globalid"]
      else
        ActiveJob::Arguments.deserialize([argument])
      end
    rescue ActiveJob::DeserializationError
      argument.to_s
    end
end
