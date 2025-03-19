class MissionControl::Jobs::GroupedJobsController < MissionControl::Jobs::ApplicationController
  def index
    if ActiveJob::Base.queue_adapter.is_a?(ActiveJob::QueueAdapters::SolidQueueAdapter)
      @grouped_jobs = SolidQueue::FailedExecution.joins(:job).group(:class_name).count
    else
      redirect_to jobs_path
    end
  end

  def active_filters?
    false
  end
end
