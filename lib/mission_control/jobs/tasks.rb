namespace :mission_control do
  namespace :jobs do
    desc "Configure HTTP Basic Authentication"
    task "authentication:configure" => :environment do
      MissionControl::Jobs::Authentication.configure
    end
  end
end
