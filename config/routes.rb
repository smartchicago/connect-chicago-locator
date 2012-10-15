TechLocator::Application.routes.draw do
  devise_for :admins

  scope "/admin" do
    resources :admins
  end
  match '/admin/admins/:id/approve' => 'admins#approve'
  
  match 'location/:slug' => 'location#show'
  match 'location/:slug(/:size)/image.jpg' => 'location#showImage'
  root :to => 'home#index'
end
