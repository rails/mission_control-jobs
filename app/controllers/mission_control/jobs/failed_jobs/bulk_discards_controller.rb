class MissionControl::Jobs::FailedJobs::BulkDiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::FailedJobFiltering

  def create
    jobs_to_discard_count = bulk_limited_filtered_failed_jobs.count
    bulk_limited_filtered_failed_jobs.discard_all

    redirect_to application_failed_jobs_url(@application), notice: "Discarded #{jobs_to_discard_count} jobs"
  end
end
