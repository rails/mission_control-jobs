class MissionControl::SolidQueueRecord < ApplicationRecord
  self.abstract_class = true

  if !ActiveRecord::Base.connection.data_source_exists?('solid_queue_jobs')
    connects_to database: { writing: :queue, reading: :queue }
  end
end
