class MissionControl::SolidQueueJob < MissionControl::SolidQueueRecord
  self.table_name = 'solid_queue_jobs'

  scope :pendings, -> { where(finished_at: nil) }
  scope :finisheds, -> { where.not(finished_at: nil) }
end
