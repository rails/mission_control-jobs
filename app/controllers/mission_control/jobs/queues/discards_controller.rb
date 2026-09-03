class MissionControl::Jobs::Queues::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::QueueScoped
  include MissionControl::Jobs::JobScoped

  def create
    unless @job.pending?
      return redirect_to application_queue_url(@application, @queue.name),
        alert: "Only pending jobs can be discarded from a queue"
    end

    @job.discard

    redirect_to application_queue_url(@application, @queue.name), notice: "Discarded job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      @queue.jobs.pending
    end
end
