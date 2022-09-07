class MissionControl::Jobs::FailedJobs::BulkDiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::ApplicationScoped

  def create
    jobs_to_discard_count = ApplicationJob.jobs.failed.count
    ApplicationJob.jobs.failed.discard_all

    redirect_to application_failed_jobs_url(@application), notice: "Discarded #{jobs_to_discard_count} jobs"
  end
end
