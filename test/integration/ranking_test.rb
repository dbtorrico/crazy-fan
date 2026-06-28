require "test_helper"

class RankingTest < ActionDispatch::IntegrationTest
  def play(user, score, played_at)
    GameResult.create!(user: user, score: score, correct_count: 3, questions_count: 5, played_at: played_at)
  end

  # Joga partidas dentro da semana corrente (a janela do ranking semanal).
  def seed_this_week
    GameResult.delete_all
    week = Time.current.beginning_of_week
    play(users(:joao), 300, week + 1.hour)
    play(users(:joao), 200, week + 2.hours)   # joao soma 500
    play(users(:maria), 250, week + 3.hours)  # maria 250
  end

  test "GET /ranking sem login retorna 200 e exibe CTA de login" do
    get ranking_path
    assert_response :success
    assert_select "a, button", /[Gg]oogle|[Ll]ogin|[Ee]ntrar/
  end

  test "GET /ranking soma os pontos da semana por usuário (1 linha por usuário)" do
    seed_this_week
    get ranking_path
    assert_response :success

    body = response.body
    # joao soma 500 e maria soma 250 — totais devem aparecer
    assert_includes body, users(:joao).nickname, "joao deve aparecer no ranking"
    assert_match(/500/, body, "deve exibir o total agregado de joao")
    assert_match(/250/, body, "deve exibir o total agregado de maria")
  end

  test "GET /ranking exibe email mascarado e nunca o completo" do
    seed_this_week
    get ranking_path
    assert_match "j***@example.com", response.body
    assert_no_match(/joao@example\.com/, response.body)
  end

  test "GET /ranking sem partidas na semana mostra estado vazio" do
    GameResult.delete_all
    play(users(:joao), 300, Time.current.beginning_of_week - 1.day)  # semana passada
    get ranking_path
    assert_response :success
    assert_match(/Nenhum resultado neste período/i, response.body)
  end
end
