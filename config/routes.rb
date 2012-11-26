TechLocator::Application.routes.draw do

  devise_for :admins

  match '/admin/admins/:id/approve' => 'admins#approve'
  match '/admin/admins/logged_in' => 'admins#logged_in'
  match '/admin/admins/is_superadmin' => 'admins#is_superadmin'
  scope "/admin" do
    resources :admins
  end
  
  match 'location/:id(/:size)/image.jpg' => 'location#showImage'
  match 'location/:id/widget' => 'location#showWidget'
  post 'location/:id/edit' => 'location#update'
  get "location/:id/delete" => 'location#destroy'
  resources :location

  get "location_changes/index"
  
  root :to => 'home#index'
end
