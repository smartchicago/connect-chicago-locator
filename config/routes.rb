TechLocator::Application.routes.draw do
  get "admin/index"

  devise_for :admins
  match 'location/:slug' => 'location#show'
  root :to => 'home#index'
end
