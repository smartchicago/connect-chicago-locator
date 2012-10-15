TechLocator::Application.routes.draw do
  devise_for :admins

  match '/admin/admins/:id/approve' => 'admins#approve'
  scope "/admin" do
    resources :admins
  end
  
  match 'location/:id(/:size)/image.jpg' => 'location#showImage'
  resources :location
  
  root :to => 'home#index'
end
