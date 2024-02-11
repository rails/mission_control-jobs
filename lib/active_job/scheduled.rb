module ActiveJob::Scheduled
  extend ActiveSupport::Concern

  def scheduled_enqueue_delayed?
    status == :scheduled && scheduled_at.before?(MissionControl::Jobs.scheduled_job_delay_threshold.ago)
  end
end
