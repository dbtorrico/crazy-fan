require "test_helper"

class GameResultTest < ActiveSupport::TestCase
  test "pertence a um usuário" do
    result = GameResult.new(
      user: users(:joao),
      score: 300,
      correct_count: 3,
      questions_count: 5
    )
    assert result.valid?
    assert_equal users(:joao), result.user
  end

  test "é inválido sem score" do
    result = GameResult.new(user: users(:joao), correct_count: 3, questions_count: 5)
    assert_not result.valid?
    assert result.errors[:score].any?
  end

  test "é inválido sem correct_count" do
    result = GameResult.new(user: users(:joao), score: 200, questions_count: 5)
    assert_not result.valid?
    assert result.errors[:correct_count].any?
  end

  # --- leaderboard (agregação por janela) ---

  # Quarta-feira fixa, para uma semana determinística (seg 2026-06-15 .. dom 2026-06-21).
  NOW = Time.zone.local(2026, 6, 17, 12, 0, 0)

  def play(user, score, played_at)
    GameResult.create!(user: user, score: score, correct_count: 3, questions_count: 5, played_at: played_at)
  end

  def setup_week
    GameResult.delete_all
    week_start = NOW.beginning_of_week
    play(users(:joao), 300, week_start + 1.hour)   # esta semana
    play(users(:joao), 200, week_start + 1.day)    # esta semana → joao soma 500
    play(users(:maria), 250, week_start + 2.days)  # esta semana
    play(users(:joao), 999, week_start - 1.day)    # semana anterior (fora da janela semanal)
    week_start
  end

  test "leaderboard semanal soma por usuário e ignora fora da janela" do
    week_start = setup_week
    rows = GameResult.leaderboard(window: week_start..).to_a

    assert_equal 2, rows.size, "um por usuário"
    joao = rows.find { |r| r.user_id == users(:joao).id }
    assert_equal 500, joao.total_score.to_i, "soma só as partidas da semana (300+200)"
    assert_equal 2, joao.plays.to_i
  end

  test "leaderboard ordena por total desc com user_id como desempate" do
    week_start = setup_week
    rows = GameResult.leaderboard(window: week_start..).to_a

    assert_equal users(:joao).id, rows.first.user_id, "joao (500) antes de maria (250)"
    assert_equal users(:maria).id, rows.last.user_id
  end

  test "leaderboard sem janela considera todas as partidas (geral agregado)" do
    setup_week
    rows = GameResult.leaderboard(window: nil).to_a
    joao = rows.find { |r| r.user_id == users(:joao).id }
    assert_equal 1499, joao.total_score.to_i, "inclui a partida da semana anterior (999)"
  end

  test "leaderboard de janela vazia retorna relação vazia" do
    GameResult.delete_all
    play(users(:joao), 300, NOW.beginning_of_week - 1.week)  # semana anterior
    rows = GameResult.leaderboard(window: NOW.beginning_of_week..).to_a
    assert_empty rows
  end

  test "leaderboard expõe nickname e email do usuário" do
    setup_week
    joao = GameResult.leaderboard(window: NOW.beginning_of_week..).find { |r| r.user_id == users(:joao).id }
    assert_equal users(:joao).nickname, joao.nickname
    assert_equal users(:joao).email, joao.email
  end

  test "beginning_of_week usa o fuso America/Sao_Paulo (segunda 00h)" do
    assert_equal "America/Sao_Paulo", Time.zone.name
    travel_to Time.zone.local(2026, 6, 15, 0, 30, 0) do  # segunda 00h30 BR
      assert_equal Time.zone.local(2026, 6, 15, 0, 0, 0), Time.current.beginning_of_week
    end
  end
end
