require "test_helper"

class GameResultSavingTest < ActionDispatch::IntegrationTest
  # Simula uma partida completa na sessão com 5 respostas
  def complete_match_in_session(user: nil)
    # Inicia partida
    post start_match_path, params: { nickname: "Teste" }

    # Responde 5 vezes (alternativa 0 em todas — não importa se erra)
    5.times do
      post match_answers_path, params: { choice: "0", timed_out: "0" }
      get next_question_match_path
    end
  end

  def sign_in_as(user)
    mock_google_auth(uid: user.uid, email: user.email, name: "Teste")
    get "/users/auth/google_oauth2/callback"
    clear_google_mock
  end

  test "partida concluída por usuário logado salva GameResult" do
    sign_in_as(users(:joao))
    assert_difference "GameResult.count", 1 do
      complete_match_in_session
    end
    result = GameResult.last
    assert_equal users(:joao), result.user
    assert result.score >= 0
    assert_equal 5, result.questions_count
  end

  test "partida concluída por convidado NÃO salva GameResult" do
    assert_no_difference "GameResult.count" do
      complete_match_in_session
    end
  end
end
