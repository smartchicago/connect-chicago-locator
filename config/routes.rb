TechLocator::Application.routes.draw do
  devise_for :admins
  match 'location/:slug' => 'location#show'
  root :to => 'home#index'
end
