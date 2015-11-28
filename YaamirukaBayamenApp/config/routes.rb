Rails.application.routes.draw do
  root 'sambavams#index'
  get 'plot' => 'sambavams#plot'
  get 'safe_routes' => 'sambavams#safe_routes'
  get 'new' => 'sambavams#new'
  post 'sambavams', to: 'sambavams#create'
end
