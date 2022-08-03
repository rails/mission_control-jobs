module MissionControl
  module Jobs
    class Engine < ::Rails::Engine
      isolate_namespace MissionControl::Jobs
    end
  end
end
