module MissionControl::Jobs::Server::Serializable
  extend ActiveSupport::Concern

  class_methods do
    # Loads a server from a locator string with the format +<application>:<server>+. For example:
    #
    #   bc4:resque_chicago
    #
    # When the +<server>+ fragment is omitted it will return the first server for the application.
    def from_global_id(global_id)
      app_id, server_id = global_id.split(":")

      application = MissionControl::Jobs.applications[app_id] or raise MissionControl::Jobs::Errors::ResourceNotFound, "No application with id #{app_id} found"
      server = server_id ? application.servers[server_id] : application.servers.first

      server or raise MissionControl::Jobs::Errors::ResourceNotFound, "No server for #{global_id} found"
    end
  end

  def to_global_id
    suffix = ":#{id}" if application.servers.many?
    "#{application&.id}#{suffix}"
  end
end
