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
end
