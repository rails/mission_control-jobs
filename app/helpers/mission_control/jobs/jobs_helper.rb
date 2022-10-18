module MissionControl::Jobs::JobsHelper
  def failed_jobs_count
    ActiveJob.jobs.failed.count
  end

  def failed_job_error(job)
    "#{job.last_execution_error.error_class}: #{job.last_execution_error.message}"
  end
end
