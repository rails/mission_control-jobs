MissionControl::Jobs::Engine.routes.draw do
  resources :applications, only: [] do
    resources :queues, only: [ :index, :show ] do
      scope module: :queues do
        resource :pause, only: [ :create, :destroy ]
      end
    end

    resources :jobs, only: :show do
      resource :retry, only: :create
      resource :discard, only: :create
      resource :dispatch, only: :create

      collection do
        resource :bulk_retries, only: :create
        resource :bulk_discards, only: :create
      end
    end

    resources :jobs, only: :index, path: ":status/jobs"

    resources :workers, only: [ :index, :show ]
    resources :recurring_tasks, only: [ :index, :show, :update ]
  end

  # Allow referencing urls without providing an application_id. It will default to the first one.
  resources :queues, only: [ :index, :show ]

  resources :jobs, only: :show
  resources :jobs, only: :index, path: ":status/jobs"

  root to: "queues#index"
end
