class BatchCallbackJob < ApplicationJob
  def perform(kind = "finish")
    Rails.logger.info "[BatchCallbackJob] #{kind} fired for batch #{batch.id}: " \
      "#{batch.status}, #{batch.completed_jobs}/#{batch.total_jobs} completed, #{batch.failed_jobs} failed"
  end
end
