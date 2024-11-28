namespace :mission_control do
  namespace :jobs do
    desc "Configure HTTP Basic Authentication"
    task "authentication:init" do
      Rails::Command.invoke :generate, [ "mission_control:jobs:authentication" ]
    end
  end
end
