class MyApplicationController < ApplicationController
  # Mimics host authentication redirecting to a host route from inside the engine, as
  # Rails' authentication generator does with +new_session_path+.
  before_action :require_authentication, if: -> { params[:require_authentication] }

  private
    def require_authentication
      redirect_to new_session_path
    end
end
