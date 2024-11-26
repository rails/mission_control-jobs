module MissionControl::Jobs::BasicAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_by_http_basic
  end

  private
    def authenticate_by_http_basic
      if http_basic_authentication_enabled?
        if http_basic_authentication_configured?
          http_basic_authenticate_or_request_with(**http_basic_authentication_credentials)
        else
          head :unauthorized
        end
      end
    end

    def http_basic_authentication_enabled?
      MissionControl::Jobs.http_basic_auth_enabled
    end

    def http_basic_authentication_configured?
      http_basic_authentication_credentials.values.all?(&:present?)
    end

    def http_basic_authentication_credentials
      {
        name: MissionControl::Jobs.http_basic_auth_user,
        password: MissionControl::Jobs.http_basic_auth_password
      }.transform_values(&:presence)
    end
end
