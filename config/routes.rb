Rails.application.routes.draw do
  # Devise — apenas OmniAuth (sem registro/senha próprios)
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [ :sessions, :passwords, :registrations, :confirmations, :unlocks ]
  devise_scope :user do
    delete "/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  # Nickname (primeiro login)
  get  "/nickname/new", to: "nicknames#new",    as: :new_nickname
  post "/nickname",     to: "nicknames#create",  as: :nickname

  # Ranking
  get "/ranking", to: "ranking#index", as: :ranking

  # Pagamentos (Mercado Pago Pix)
  post "/payments/create",  to: "payments#create",  as: :create_payments
  post "/payments/webhook", to: "payments#webhook", as: :payments_webhook
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Torcedor Maluco — Quiz da Copa (root)
  # Estado da partida vive em session[:match]; sem :id.
  resource :match, only: [], controller: "matches" do
    post :start
    get  :next_question
    resources :answers, only: :create   # POST /match/answers
  end

  # Games (fluxo legado — mantido enquanto há dependências)
  get  "games/new",    to: "games#new",    as: :new_game
  post "games",        to: "games#create", as: :games
  get  "games/play",   to: "games#show",   as: :play_game
  post "games/answer", to: "games#answer", as: :answer_games
  get  "games/result", to: "games#result", as: :result_games

  root "matches#show"

  if Rails.env.development?
    scope :dev do
      get :login,            to: "dev#login",            as: :dev_login
      get :activate_premium, to: "dev#activate_premium", as: :dev_activate_premium
      get :expire_premium,   to: "dev#expire_premium",   as: :dev_expire_premium
      get :zero_energy,      to: "dev#zero_energy",      as: :dev_zero_energy
      get :full_energy,      to: "dev#full_energy",      as: :dev_full_energy
      get :payment,          to: "dev#payment",           as: :dev_payment
    end
  end
end
