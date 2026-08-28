# Route helpers of the host app that the engine doesn't define itself, routed through +main_app+.
#
# Mission Control's controllers inherit from the host app's +ApplicationController+ (see
# +base_controller_class+), so host code such as a +before_action+ redirecting to
# +new_session_path+ runs inside the engine, where route helpers resolve against the engine's
# routes and raise +ActionController::UrlGenerationError+. This module defines, for every route
# helper the host app has and the engine doesn't, a method delegating to the host app's routes,
# so that code keeps working unchanged.
#
# Helpers defined by both, like +root_path+, keep resolving to the engine's, as in any isolated
# engine; use +main_app.root_path+ for the host's.
module MissionControl::Jobs::HostRouteHelpers
  class << self
    def define_from(host_routes, engine_routes)
      undefine_all

      (host_routes.named_routes.helper_names - engine_routes.named_routes.helper_names).each do |name|
        define_method(name) { |*args| main_app.public_send(name, *args) }
        defined_helpers << name
      end
    end

    private
      def undefine_all
        defined_helpers.each { |name| remove_method(name) }
        defined_helpers.clear
      end

      def defined_helpers
        @defined_helpers ||= []
      end
  end
end
