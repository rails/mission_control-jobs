module ActiveJob::Scheduled
  extend ActiveSupport::Concern

  def scheduled_enqueue_delayed?
    status == :scheduled && scheduled_at.before?(1.minute.ago)
  end
end
