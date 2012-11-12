EnjuTrunkCirculation::Engine.routes.draw do

  resources :users do
    resources :baskets do
      resources :checked_items
      resources :checkins
    end
    resources :checkouts
    resources :reserves
  end

  resources :baskets do
    resources :checked_items
  end

  resources :checkins
  resources :checked_items

  resources :checkouts do
    collection do
      post 'output'
      post 'extend'
    end
  end

  resources :reserves do
    post :output, :on => :member
  end

  resources :manifestation do
    resources :reserves
  end
  resources :items do
    resources :checked_items
  end
 
end
