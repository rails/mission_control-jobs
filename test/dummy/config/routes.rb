Rails.application.routes.draw do
  root to: redirect("/jobs")
  resource :session, only: :new

  mount MissionControl::Jobs::Engine => "/jobs"
end
