Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get  "games/new",    to: "games#new",    as: :new_game
  post "games",        to: "games#create",  as: :games
  get  "games/play",   to: "games#show",   as: :play_game
  post "games/answer", to: "games#answer",  as: :answer_games
  get  "games/result", to: "games#result",  as: :result_games

  root to: redirect("/games/new")
end
