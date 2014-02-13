LocalOrbit::Application.routes.draw do

  devise_for :users
  devise_scope :user do
    get "/login" => "devise/sessions#new"
  end

  namespace :admin do
    resources :markets do
      resources :market_managers, as: :managers, path: :managers
    end

    resources :organizations do
      resources :users
      resources :locations, except: :destroy do
        collection do
          delete :destroy
        end
      end
    end

    resources :products do
      resources :lots
    end
  end

  resource :dashboard, controller: "dashboard"

  resources :organizations, only: [] do
    resources :locations, only: [:index]
  end

  root to: redirect('/login')
end
