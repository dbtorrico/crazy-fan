class GamesController < ApplicationController
  def new
  end

  def create
    question_ids = Question.pluck(:id).sample(5)

    if question_ids.size < 5
      render :insufficient_questions and return
    end

    session[:game] = { "question_ids" => question_ids, "current_index" => 0, "score" => 0 }
    @question = Question.includes(:answers).find(question_ids.first)
    render :show
  end

  def answer
    game = session[:game]
    return redirect_to new_game_path unless game

    expected_question_id = game["question_ids"][game["current_index"]]
    answer = Answer.find_by(id: params[:answer_id], question_id: expected_question_id)
    game["score"] += 1 if answer&.correta

    next_index = game["current_index"] + 1
    game["current_index"] = next_index
    session[:game] = game

    if next_index >= 5
      redirect_to result_games_path
    else
      @question = Question.includes(:answers).find(game["question_ids"][next_index])
      render :show
    end
  end

  def result
    @score = session.dig(:game, "score") || 0
    session.delete(:game)
  end
end
