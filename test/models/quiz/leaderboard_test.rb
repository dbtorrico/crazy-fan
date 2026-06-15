require "test_helper"

class Quiz::LeaderboardTest < ActiveSupport::TestCase
  NOW = Time.zone.local(2026, 6, 17, 12, 0, 0)  # quarta; semana seg 2026-06-15

  def play(user, score, played_at)
    GameResult.create!(user: user, score: score, correct_count: 3, questions_count: 5, played_at: played_at)
  end

  def setup_week
    GameResult.delete_all
    week_start = NOW.beginning_of_week
    play(users(:joao), 300, week_start + 1.hour)
    play(users(:joao), 200, week_start + 1.day)    # joao soma 500, 2 partidas
    play(users(:maria), 250, week_start + 2.days)  # maria 250, 1 partida
  end

  # --- períodos ---

  test "periods expõe o registro e weekly é o default" do
    assert_equal :weekly, Quiz::Leaderboard.periods.first.key
    assert_equal :weekly, Quiz::Leaderboard.find_period("invalido").key
    assert_equal :weekly, Quiz::Leaderboard.find_period(:weekly).key
  end

  # --- montagem das entries ---

  test "for(:weekly) soma por usuário, numera rank e ordena por total" do
    setup_week
    entries = Quiz::Leaderboard.for(:weekly, now: NOW)

    assert_equal 2, entries.size
    assert_equal [ 1, 2 ], entries.map(&:rank)
    assert_equal users(:joao).id, entries.first.user_id
    assert_equal 500, entries.first.value
  end

  test "detail usa singular/plural conforme o nº de partidas" do
    setup_week
    entries = Quiz::Leaderboard.for(:weekly, now: NOW)
    joao  = entries.find { |e| e.user_id == users(:joao).id }
    maria = entries.find { |e| e.user_id == users(:maria).id }

    assert_equal "2 partidas", joao.detail
    assert_equal "1 partida", maria.detail
  end

  test "nickname ausente vira Anônimo" do
    setup_week  # maria não tem nickname
    maria = Quiz::Leaderboard.for(:weekly, now: NOW).find { |e| e.user_id == users(:maria).id }
    assert_equal "Anônimo", maria.nickname
  end

  test "entry traz o email mascarado, nunca o completo" do
    setup_week
    joao = Quiz::Leaderboard.for(:weekly, now: NOW).find { |e| e.user_id == users(:joao).id }
    assert_equal "j***@example.com", joao.masked_email
    assert_not_includes joao.masked_email, "joao@example.com"
  end

  # --- mascaramento ---

  test "mask_email oculta o local" do
    assert_equal "d***@gmail.com", Quiz::Leaderboard.mask_email("daniel@gmail.com")
    assert_equal "a***@x.com",     Quiz::Leaderboard.mask_email("a@x.com")
  end

  test "mask_email lida com vazio/inválido sem vazar" do
    assert_equal "", Quiz::Leaderboard.mask_email(nil)
    assert_equal "", Quiz::Leaderboard.mask_email("")
    assert_equal "", Quiz::Leaderboard.mask_email("semarroba")
  end
end
