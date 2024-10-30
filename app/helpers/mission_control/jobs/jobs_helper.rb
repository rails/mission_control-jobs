module MissionControl::Jobs::JobsHelper
  def job_title(job)
    job.job_class_name
  end

  def job_arguments(job)
    renderable_job_arguments_for(job).join(", ")
  end

  def failed_job_error(job)
    "#{job.last_execution_error.error_class}: #{job.last_execution_error.message}"
  end

  def clean_backtrace?
    params["clean_backtrace"] == "true"
  end

  def failed_job_backtrace(job, server)
    if clean_backtrace? && server&.backtrace_cleaner
      server.backtrace_cleaner.clean(job.last_execution_error.backtrace).join("\n")
    else
      job.last_execution_error.backtrace.join("\n")
    end
  end

  def attribute_names_for_job_status(status)
    case status.to_s
    when "failed"      then [ "Error", "" ]
    when "blocked"     then [ "Queue", "Blocked by", "Block expiry", "" ]
    when "finished"    then [ "Queue", "Finished" ]
    when "scheduled"   then [ "Queue", "Scheduled", "" ]
    when "in_progress" then [ "Queue", "Run by", "Running since" ]
    else               []
    end
  end

  def job_delayed?(job)
    job.scheduled_at.before?(MissionControl::Jobs.scheduled_job_delay_threshold.ago)
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
      "(#{argument.collect { |part| as_renderable_argument(part) }.join(", ")})"
    end
end
