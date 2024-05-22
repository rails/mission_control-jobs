require "irb/command"

module MissionControl::Jobs::Console
  class ConnectTo < IRB::Command::Base
    category "Mission control jobs"
    description "Connect to a job server"

    def execute(server_locator)
      server = MissionControl::Jobs::Server.from_global_id(server_locator)
      MissionControl::Jobs::Current.server = server

      puts "Connected to #{server_locator}"
    end
  end
end
