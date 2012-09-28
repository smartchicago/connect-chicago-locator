TechLocator::Application.routes.draw do
	resources :admin
  devise_for :admins
  match 'location/:slug' => 'location#show'
  match 'location/image/:slug' => 'location#showImage'
  root :to => 'home#index'
end
