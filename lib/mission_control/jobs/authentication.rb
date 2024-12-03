require "rails/command"

class MissionControl::Jobs::Authentication < Rails::Command::Base
  def self.configure
    new.configure
  end

  def configure
    if credentials_accessible?
      if authentication_configured?
        say "HTTP Basic Authentication is already configured for `#{Rails.env}`. You can edit it using `credentials:edit`"
      else
        say "Setting up credentials for HTTP Basic Authentication for `#{Rails.env}` environment."
        say ""

        username = ask "Enter username: "
        password = SecureRandom.base58(64)

        store_credentials(username, password)
        say "Username and password stored in Rails encrypted credentials."
        say ""
        say "You can now access Mission Control – Jobs with: "
        say ""
        say " - Username: #{username}"
        say " - password: #{password}"
        say ""
        say "You can also edit these in the future via `credentials:edit`"
      end
    else
      say "Rails credentials haven't been configured or aren't accessible. Configure them following the instructions in `credentials:help`"
    end
  end

  private
    attr_reader :environment

    def credentials_accessible?
      credentials.read.present?
    end

    def authentication_configured?
      %i[ http_basic_auth_user http_basic_auth_password ].any? do |key|
        credentials.dig(:mission_control, key).present?
      end
    end

    def store_credentials(username, password)
      content = credentials.read + "\n" + http_authentication_entry(username, password) + "\n"
      credentials.write(content)
    end

    def credentials
      @credentials ||= Rails.application.encrypted(config.content_path, key_path: config.key_path)
    end

    def config
      Rails.application.config.credentials
    end

    def http_authentication_entry(username, password)
      <<~ENTRY
        mission_control:
          http_basic_auth_user: #{username}
          http_basic_auth_password: #{password}
      ENTRY
    end
end
