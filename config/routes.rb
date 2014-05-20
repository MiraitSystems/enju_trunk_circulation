EnjuTrunkCirculation::Engine.routes.draw do
end

Rails.application.routes.draw do
  get "checkout_histories/index"

  resources :baskets do
    resources :checked_items
  end

  resources :checked_items

  resources :checkins

  resources :checkouts do
    collection do
      post 'output'
      post 'extend'
      get 'extend'
      post 'extend_checkout'  
    end
  end

  resources :items do
    resources :checked_items
  end

  resources :manifestations do
    resources :reserves
  end

  resources :reserves do
    post :output, :on => :member
    get :output_pdf, :on => :member
    get :retain, :on => :collection
    post :retain_item, :on => :collection
    post :informed, :on => :member
  end

  resources :users do
    resources :baskets do
      resources :checked_items
      resources :checkins
    end
    resources :checkouts
    resources :reserves
  end

  match '/batch_checkin' => 'checkins#batchexec' , :via => :post
  match '/batch_checkout' => 'checkouts#batchexec' , :via => :post 

  # for opac begin
  scope "opac", :path => "opac", :as => "opac" do
    resources :users do
      resources :reserves, :opac => true
      resources :checkouts, :opac => true
    end
  end
  # for opac end
end
