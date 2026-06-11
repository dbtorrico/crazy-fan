class GamesController < ApplicationController
  def new
  end

  def create
    question_ids = Question.pluck(:id).sample(5)

    if question_ids.size < 5
      render :insufficient_questions and return
    end

    session[:game] = {
      "question_ids"  => question_ids,
      "current_index" => 0,
      "score"         => 0,
      "correct"       => 0,
      "nickname"      => params[:nickname].to_s.strip.slice(0, 18)
    }
    redirect_to play_game_path
  end

  def show
    game = session[:game]
    return redirect_to new_game_path unless game

    idx = game["current_index"].to_i
    return redirect_to result_games_path if idx >= 5

    @question      = Question.includes(:answers).find(game["question_ids"][idx])
    @current_index = idx
    @score         = game["score"] || 0
  end

  def answer
    game = session[:game]
    return redirect_to new_game_path unless game

    expected_question_id = game["question_ids"][game["current_index"]]
    answer = Answer.find_by(id: params[:answer_id], question_id: expected_question_id)
    if answer&.correta
      game["score"]   += 100
      game["correct"]  = (game["correct"] || 0) + 1
    end

    next_index = game["current_index"] + 1
    game["current_index"] = next_index
    session[:game] = game

    if next_index >= 5
      redirect_to result_games_path
    else
      redirect_to play_game_path
    end
  end

  def result
    @score    = session.dig(:game, "score")   || 0
    @correct  = session.dig(:game, "correct") || 0
    @nickname = session.dig(:game, "nickname") || ""
    session.delete(:game)
  end
end
