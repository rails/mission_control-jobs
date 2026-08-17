class MissionControl::Jobs::Dashboard
  attr_reader :statuses

  def initialize(statuses:, jobs: ActiveJob.jobs)
    @statuses = statuses
    @jobs = jobs
  end

  def snapshot
    {
      recorded_at: Time.current.iso8601(3),
      counts: normalized_counts
    }
  end

  private
    attr_reader :jobs

    def normalized_counts
      jobs.counts_by_status(statuses: statuses).transform_values do |count|
        { value: count.finite? ? count : nil, exact: count.finite? }
      end
    end
end
