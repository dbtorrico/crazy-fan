class AnswersController < ApplicationController
  layout "matches"

  def create
    @match = Quiz::MatchState.load(session[:match])
    return redirect_to(root_path) if @match.nil?

    @match.answer!(
      choice:    params[:choice],
      timed_out: params[:timed_out] == "1"
    )
    session[:match] = @match.to_h

    @screen = :question
    render "matches/show"
  end
end
