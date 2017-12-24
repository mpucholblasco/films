Rails.application.routes.draw do
# Welcome (main) page
  get  'welcome/index'
  root 'welcome#index'

  # Disks
  get  'disks/:id/update_content' => 'disks#update_content', as: :update_content
  get  'disks/:id/update_content/:jobid' => 'disks#update_content_info', as: :update_content_info
  post 'disks/:id/update_content' => 'disks#updating_content', as: :updating_content

  # Downloads
  get  'downloads' => 'downloads#index'
  post 'downloads' => 'downloads#store'

  # Files
  get 'files' => 'file#index'

  # Jobs
  resources :jobs, only: [:index,:show,:destroy,:update]

  # Tools
  get 'tools' => 'tools#index'
  get 'tools/find_duplicates' => 'tools#find_duplicates'
  get 'tools/find_series_duplicates' => 'tools#find_series_duplicates'
  get 'tools/stop_amule' => 'tools#stop_amule'
  get 'tools/start_amule' => 'tools#start_amule'
  get 'tools/copy_from_server_to_external' => 'tools#copy_from_server_to_external'
  get 'tools/copy_from_server_to_external/:id' => 'tools#copy_from_server_to_external_status'

  # Resources
  resources :disks do
    resources :file_disks
  end

# The priority is based upon order of creation: first created -> highest priority.
# See how all your routes lay out with "rake routes".

# You can have the root of your site routed with "root"
# root 'welcome#index'

# Example of regular route:
#   get 'products/:id' => 'catalog#view'

# Example of named route that can be invoked with purchase_url(id: product.id)
#   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

# Example resource route (maps HTTP verbs to controller actions automatically):
#   resources :products

# Example resource route with options:
#   resources :products do
#     member do
#       get 'short'
#       post 'toggle'
#     end
#
#     collection do
#       get 'sold'
#     end
#   end

# Example resource route with sub-resources:
#   resources :products do
#     resources :comments, :sales
#     resource :seller
#   end

# Example resource route with more complex sub-resources:
#   resources :products do
#     resources :comments
#     resources :sales do
#       get 'recent', on: :collection
#     end
#   end

# Example resource route with concerns:
#   concern :toggleable do
#     post 'toggle'
#   end
#   resources :posts, concerns: :toggleable
#   resources :photos, concerns: :toggleable

# Example resource route within a namespace:
#   namespace :admin do
#     # Directs /admin/products/* to Admin::ProductsController
#     # (app/controllers/admin/products_controller.rb)
#     resources :products
#   end
end
