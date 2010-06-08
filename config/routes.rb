Salesflip::Application.routes.draw do |map|

  root :to => 'pages#index'

  match 'profile', :to => 'users#profile'

  #devise_for :users, :admins

  resources :users, :comments, :tasks, :accounts, :contacts, :attachments, :deleted_items,
    :searches

  resources :leads do
    member do
      get :convert
      put :promote
      put :reject
    end
  end

  namespace :admin do
    root :to => 'configurations#show'
    resource :configuration
  end
end
