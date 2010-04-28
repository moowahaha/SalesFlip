ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'pages'

  map.profile '/profile', :controller => 'users', :action => 'profile'

  map.devise_for :users, :admins
  map.resources :freelancers, :controller => 'users'
  map.resources :users
  map.resources :leads, :member => { :convert => :get, :promote => :put, :reject => :put }
  map.resources :comments
  map.resources :tasks
  map.resources :accounts
  map.resources :contacts
  map.resources :attachments
  map.resources :deleted_items
  map.resources :searches
  map.resources :invitations

  map.namespace(:admin) do |admin|
    admin.root :controller => 'configurations', :action => 'show'
    admin.resource :configuration
  end
end
