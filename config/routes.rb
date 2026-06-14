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
end
