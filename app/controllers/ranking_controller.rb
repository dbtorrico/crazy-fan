class RankingController < ApplicationController
  layout "matches"

  def index
    @results = GameResult.order(score: :desc).limit(50).includes(:user)
  end
end
