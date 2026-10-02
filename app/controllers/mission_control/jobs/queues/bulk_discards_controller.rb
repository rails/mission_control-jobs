class MissionControl::Jobs::Queues::BulkDiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped

  def create
    pending_jobs = @queue.jobs.pending
    count = pending_jobs.count
    pending_jobs.discard_all

    redirect_back fallback_location: application_queue_url(@application, @queue.name), notice: "Discarded #{count} pending #{"job".pluralize(count)}"
  end
end
