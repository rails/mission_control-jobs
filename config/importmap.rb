pin "application", to: "mission_control/jobs/application.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from MissionControl::Jobs::Engine.root.join("app/javascript/mission_control/jobs/controllers"), under: "controllers", to: "mission_control/jobs/controllers"
