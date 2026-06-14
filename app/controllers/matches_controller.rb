class MatchesController < ApplicationController
  layout "matches"
  before_action :load_match

  def show
    if params[:reset] || @match.nil? || @match.finished?
      reset_match
      @match  = nil
      @screen = :home
    else
      @screen = @match.screen
    end
    @is_guest = !user_signed_in?
  end

  def start
    @match  = Quiz::MatchState.start(nickname: params[:nickname])
    save_match
    @screen = :question
    render :show
  end

  def next_question
    return redirect_to(root_path) if @match.nil?
    @match.advance!
    save_match

    if @match.finished? && user_signed_in?
      GameResult.create(
        user:            current_user,
        score:           @match.score,
        correct_count:   @match.correct_count,
        questions_count: @match.total
      )
    end

    @is_guest = !user_signed_in?
    @screen   = @match.screen
    render :show
  end

  private

  def load_match
    @match = Quiz::MatchState.load(session[:match])
  end

  def save_match
    session[:match] = @match.to_h
  end

  def reset_match
    session.delete(:match)
  end
end
