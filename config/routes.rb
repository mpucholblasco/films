Rails.application.routes.draw do
  get "health" => "rails/health#show", as: :rails_health_check

  # Welcome (main) page
  get  "welcome/index"
  root "welcome#index"

  # Disks
  post "disks/:id/update_content" => "disks#update_content", as: :update_content

  # Downloads
  get  "downloads" => "downloads#index"
  post "downloads" => "downloads#store"

  # Files
  get "files" => "file#index"

  # Jobs
  resources :jobs, only: [ :index, :show, :destroy, :update ]

  # Tools
  get "tools" => "tools#index"
  get "tools/find_duplicated_movies" => "tools#find_duplicated_movies"
  get "tools/find_duplicated_series" => "tools#find_duplicated_series"
  get "tools/stop_amule" => "tools#stop_amule"
  get "tools/start_amule" => "tools#start_amule"
  get "tools/copy_from_server_to_external" => "tools#copy_from_server_to_external"
  get "tools/copy_from_server_to_external/:id" => "tools#copy_from_server_to_external_status"

  # Resources
  resources :disks do
    resources :file_disks
  end
end
