MissionControl::Jobs::Engine.routes.draw do
  resources :applications do
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
        resource :discard, only: :create
      end
    end

    namespace :failed_jobs do
      resource :bulk_retry, only: :create
      resource :bulk_discard, only: :create
    end
  end

  # Allow referencing resources urls without providing an application_id. It will default to the first one.
  resources :queues, :failed_jobs

  root to: "queues#index"
end
