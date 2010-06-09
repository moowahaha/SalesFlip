Salesflip::Application.routes.draw do |map|
  devise_for :admins

  devise_for :users

  root :to => 'pages#index'

  match 'profile', :to => 'users#profile'

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
