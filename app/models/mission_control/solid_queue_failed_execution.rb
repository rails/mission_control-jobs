class MissionControl::SolidQueueFailedExecution < MissionControl::SolidQueueRecord
  self.table_name = 'solid_queue_failed_executions'
end
