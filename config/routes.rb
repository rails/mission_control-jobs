MissionControl::Jobs::Engine.routes.draw do
  resources :queues

  root to: "queues#index"
end
