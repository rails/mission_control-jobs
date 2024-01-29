Rails.application.routes.draw do
  root to: redirect("/jobs")

  mount MissionControl::Jobs::Engine => "/jobs"
end
