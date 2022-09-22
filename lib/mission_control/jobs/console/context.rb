module MissionControl::Jobs::Console::Context
  mattr_accessor :jobs_server

  def evaluate(line, line_no, exception: nil)
    if MissionControl::Jobs::Current.server
      MissionControl::Jobs::Current.server.activating { super }
    else
      super
    end
  end
end
