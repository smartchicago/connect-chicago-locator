TechLocator::Application.routes.draw do

  devise_for :admins

  match '/admin/admins/:id/approve' => 'admins#approve'
  scope "/admin" do
    resources :admins
  end
  
  match 'location/:id(/:size)/image.jpg' => 'location#showImage'
  match 'location/:id/widget' => 'location#showWidget'
  post 'location/:id/edit' => 'location#update'
  resources :location

  get "location_changes/index"
  
  root :to => 'home#index'
end
