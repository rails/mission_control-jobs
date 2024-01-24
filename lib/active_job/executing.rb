# TODO: These (or a version of them) should be moved to +ActiveJob::Core+
# and related concerns when upstreamed.
module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    attr_accessor :raw_data, :position
    attr_reader :serialized_arguments
    attr_writer :status

    thread_cattr_accessor :current_queue_adapter
  end

  class_methods do
    def queue_adapter
      ActiveJob::Base.current_queue_adapter || super
    end
  end

  def retry
    ActiveJob.jobs.failed.retry_job(self)
  end

  def discard
    jobs_relation.discard_job(self)
  end

  def status
    return @status if @status.present?

    failed? ? :failed : :pending
  end

  private
    def jobs_relation
      case status
      when :failed  then ActiveJob.jobs.failed
      when :pending then ActiveJob.jobs.pending.where(queue_name: queue_name)
      else
        ActiveJob.jobs
      end
    end
end
