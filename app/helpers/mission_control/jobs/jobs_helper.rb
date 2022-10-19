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
      case argument
      when Hash
        as_renderable_hash(argument)
      when Array
        as_renderable_array(argument)
      else
        ActiveJob::Arguments.deserialize([ argument ])
      end
    rescue ActiveJob::DeserializationError
      argument.to_s
    end

    def as_renderable_hash(argument)
      if argument["_aj_globalid"]
        # don't deserialize as the class might not exist in the host app running the engine
        argument["_aj_globalid"]
      elsif argument["_aj_serialized"] == "ActiveJob::Serializers::ModuleSerializer"
        argument["value"]
      else
        ActiveJob::Arguments.deserialize([ argument ])
      end
    end

    def as_renderable_array(argument)
      argument.collect { |part| as_renderable_argument(part) }
    end
end
