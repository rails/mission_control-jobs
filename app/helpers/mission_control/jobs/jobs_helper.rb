module MissionControl::Jobs::JobsHelper
  def failed_jobs_count
    ActiveJob.jobs.failed.count
  end
end
