class MissionControl::Jobs::InternalApi::DashboardController < MissionControl::Jobs.base_controller_class.constantize
  include ActionView::Helpers::NumberHelper

  def index
    render json: {
      uptime: {
        label: Time.now.strftime("%H:%M:%S"),
        pending: queue_job.pendings.where.not(id: failed_execution.select(:job_id)).size,
        failed: failed_execution.where("created_at >= ?", time_to_consult.seconds.ago).size,
        finished: queue_job.finisheds.where("finished_at >= ?", time_to_consult.seconds.ago).size,
      },
      total: {
        failed: number_with_delimiter(ActiveJob.jobs.failed.count),
        pending: number_with_delimiter(ActiveJob.jobs.pending.count),
        scheduled: number_with_delimiter(ActiveJob.jobs.scheduled.count),
        in_progress: number_with_delimiter(ActiveJob.jobs.in_progress.count),
        finished: number_with_delimiter(ActiveJob.jobs.finished.count)
      }
    },
    status: :ok
  end

  private
    def time_to_consult
      params[:uptime].to_i || 5
    end

    def failed_execution
      MissionControl::SolidQueueFailedExecution
    end

    def queue_job
      MissionControl::SolidQueueJob
    end
end
