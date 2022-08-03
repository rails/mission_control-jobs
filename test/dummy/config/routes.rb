Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine => "/mission_control-jobs"
end
