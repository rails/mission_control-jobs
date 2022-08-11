MissionControl::Jobs::Engine.routes.draw do
  resources :queues do
    scope module: :queues do
      resource :status, controller: "status", only: [] do
        put "pause", "resume", on: :member
      end
    end
  end

  resources :failed_jobs do
    scope module: :failed_jobs do
      resource :retry, only: :create
    end
  end

  namespace :failed_jobs do
    resource :bulk_retry, only: :create
  end

  root to: "queues#index"
end
