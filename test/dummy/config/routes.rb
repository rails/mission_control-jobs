Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine => "/jobs"
end
