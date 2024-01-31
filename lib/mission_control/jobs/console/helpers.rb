module MissionControl::Jobs::Console::Helpers
  def connect_to(server_locator)
    server = MissionControl::Jobs::Server.from_global_id(server_locator)
    MissionControl::Jobs::Current.server = server

    puts "Connected to #{server_locator}"
    nil
  end

  def jobs_help
    puts "You are currently connected to #{MissionControl::Jobs::Current.server}" if MissionControl::Jobs::Current.server

    puts "You can connect to a job server with"
    puts '  connect_to "<app_id>:<server_id>"\n\n'

    puts "Available job servers:\n"

    MissionControl::Jobs.applications.each do |application|
      application.servers.each do |server|
        puts "  * #{server.to_global_id}"
      end
    end

    nil
  end
end
