class ApplicationController < (ENV["API_ONLY"] == "1" ? ActionController::API : ActionController::Base)
end
