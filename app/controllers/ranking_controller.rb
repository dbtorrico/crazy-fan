class RankingController < ApplicationController
  layout "matches"

  def index
    @periods = Quiz::Leaderboard.periods
    @period  = Quiz::Leaderboard.find_period(params[:period])
    @entries = Quiz::Leaderboard.for(@period.key)
  end
end
