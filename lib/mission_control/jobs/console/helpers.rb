module MissionControl::Jobs::Console::Helpers
  def connect_to(url)
    app_id, server_id = url.split(":")
    application = MissionControl::Jobs.applications[app_id] or raise MissionControl::Jobs::Errors::ResourceNotFound, "No application with id #{app_id} found"
    server = (application.servers[server_id] || application.servers.first) or raise MissionControl::Jobs::Errors::ResourceNotFound, "No jobs server with id #{server_id} found in #{application.name}"

    MissionControl::Jobs::Current.application = application
    MissionControl::Jobs::Current.server = server

    puts "Connected to #{application.name} (#{server.name})"
    nil
  end

  def jobs_help
    puts "You are currently connected to #{MissionControl::Jobs::Current.server}" if MissionControl::Jobs::Current.server

    puts "You can connect to a job server with"
    puts "  connect_to <app_id>:<server_id>\n\n"

    puts "Available job servers:\n"

    MissionControl::Jobs.applications.each do |application|
      application.servers.each do |server|
        suffix = ":#{server.id}" if application.servers.length > 1
        puts "\t * #{application.id}#{suffix}"
      end
    end

    nil
  end
end
