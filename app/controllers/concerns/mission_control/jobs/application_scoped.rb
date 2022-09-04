module MissionControl::Jobs
  module ApplicationScoped
    extend ActiveSupport::Concern

    included do
      before_action :set_application
      before_action :set_server

      delegate :applications, to: MissionControl::Jobs
    end

    private
      def set_application
        @application = find_application or raise Errors::ResourceNotFound, "Application not found"
        Current.application = @application
      end

      def find_application
        if params[:application_id]
          applications[params[:application_id]]
        else
          applications.first
        end
      end

      def set_server
        @server = find_server or raise Errors::ResourceNotFound, "Server not found"
        Current.server = @server
      end

      def find_server
        if params[:server_id]
          Current.application.find_server(params[:server_id])
        else
          @application.servers.first
        end
      end
  end
end
