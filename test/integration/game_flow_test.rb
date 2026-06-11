require "test_helper"

class GameFlowTest < ActionDispatch::IntegrationTest
  def create_questions(count)
    count.times.map do |i|
      q = Question.create!(enunciado: "Pergunta #{i + 1} de futebol?", tema: "Copa", dificuldade: "facil")
      q.answers.create!(texto: "Resposta correta", correta: true)
      q.answers.create!(texto: "Errada 1", correta: false)
      q.answers.create!(texto: "Errada 2", correta: false)
      q.answers.create!(texto: "Errada 3", correta: false)
      q
    end
  end

  test "POST /games com banco populado inicia partida e mostra 1ª pergunta" do
    create_questions(5)
    post games_path
    assert_response :success
    assert_select "p", /Pergunta 1 de 5/
  end

  test "POST /games com banco vazio mostra aviso amigável sem erro 500" do
    Answer.delete_all
    Question.delete_all
    post games_path
    assert_response :success
    assert_select "p", /Estamos preparando mais perguntas/
  end

  test "resposta correta soma ponto e resposta errada nao soma" do
    create_questions(5)
    post games_path

    question_ids = session[:game]["question_ids"]

    correct_answer = Answer.find_by(question_id: question_ids[0], correta: true)
    post answer_games_path, params: { answer_id: correct_answer.id }
    assert_equal 1, session[:game]["score"]

    wrong_answer = Answer.find_by(question_id: question_ids[1], correta: false)
    post answer_games_path, params: { answer_id: wrong_answer.id }
    assert_equal 1, session[:game]["score"]
  end

  test "3 certas e 2 erradas resulta em pontuacao 3 de 5" do
    create_questions(5)
    post games_path

    question_ids = session[:game]["question_ids"]
    question_ids.each_with_index do |question_id, i|
      answer = if i < 3
        Answer.find_by(question_id: question_id, correta: true)
      else
        Answer.find_by(question_id: question_id, correta: false)
      end
      post answer_games_path, params: { answer_id: answer.id }
    end

    assert_response :redirect
    follow_redirect!
    assert_select "p", /3 de 5/
  end

  test "timeout (sem answer_id) conta como erro e avanca" do
    questions = create_questions(5)
    post games_path

    score_antes = session[:game]["score"]
    post answer_games_path, params: {}
    assert_equal score_antes, session[:game]["score"]
  end

  test "contador de pergunta avança após cada resposta" do
    create_questions(5)
    post games_path
    assert_select "p", /Pergunta 1 de 5/

    question_ids = session[:game]["question_ids"]

    correct = Answer.find_by(question_id: question_ids[0], correta: true)
    post answer_games_path, params: { answer_id: correct.id }
    assert_select "p", /Pergunta 2 de 5/

    wrong = Answer.find_by(question_id: question_ids[1], correta: false)
    post answer_games_path, params: { answer_id: wrong.id }
    assert_select "p", /Pergunta 3 de 5/
  end
end
