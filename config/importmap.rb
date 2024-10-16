with_options preload: "mcj" do
  pin "mcj", to: "mission_control/jobs/application.js"

  pin "mcj-@hotwired/turbo-rails", to: "turbo.min.js"
  pin "mcj-@hotwired/stimulus", to: "stimulus.min.js"
  pin "mcj-@hotwired/stimulus-loading", to: "stimulus-loading.js"

  pin_all_from MissionControl::Jobs::Engine.root.join("app/javascript/mission_control/jobs/controllers"),
    under: "mcj-controllers",
    to: "mission_control/jobs/controllers"

  pin_all_from MissionControl::Jobs::Engine.root.join("app/javascript/mission_control/jobs/helpers"),
    under: "mcj-helpers",
    to: "mission_control/jobs/helpers"
end
