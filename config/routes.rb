Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/forgot_password", to: "auth#forgot_password"
      post "auth/reset_password", to: "auth#reset_password"
      put "auth/change_password", to: "auth#change_password"

      # Resource routes
      resources :books, only: [:index, :create, :destroy, :show, :update]
    end
  end
end
