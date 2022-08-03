module MissionControl
  module Jobs
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
