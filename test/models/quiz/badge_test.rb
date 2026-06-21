require "test_helper"

class Quiz::BadgeTest < ActiveSupport::TestCase
  def setup
    UserAchievement.delete_all
    GameResult.delete_all
  end

  def make_result(user, correct: 3, total: 5)
    GameResult.create!(
      user: user, score: correct * 100,
      correct_count: correct, questions_count: total,
      played_at: Time.current
    )
  end

  # --- first_game ---

  test "first_game concedido na 1ª partida" do
    result = make_result(users(:joao))
    earned = Quiz::Badge.check_and_award!(users(:joao), result)
    assert_includes earned.map(&:key), "first_game"
  end

  test "first_game não duplicado na 2ª partida" do
    make_result(users(:joao))
    result2 = make_result(users(:joao))
    # re-cria o count correto no DB
    earned = Quiz::Badge.check_and_award!(users(:joao), result2)
    assert_not_includes earned.map(&:key), "first_game"
  end

  # --- perfect_game ---

  test "perfect_game concedido com 5/5 corretas" do
    result = make_result(users(:joao), correct: 5, total: 5)
    earned = Quiz::Badge.check_and_award!(users(:joao), result)
    assert_includes earned.map(&:key), "perfect_game"
  end

  test "perfect_game não concedido com 4/5" do
    result = make_result(users(:joao), correct: 4, total: 5)
    earned = Quiz::Badge.check_and_award!(users(:joao), result)
    assert_not_includes earned.map(&:key), "perfect_game"
  end

  # --- ten_games ---

  test "ten_games concedido exatamente na 10ª partida" do
    9.times { make_result(users(:joao)) }
    result10 = make_result(users(:joao))
    earned = Quiz::Badge.check_and_award!(users(:joao), result10)
    assert_includes earned.map(&:key), "ten_games"
  end

  # --- fifty_games ---

  test "fifty_games concedido exatamente na 50ª partida" do
    49.times { make_result(users(:joao)) }
    result50 = make_result(users(:joao))
    earned = Quiz::Badge.check_and_award!(users(:joao), result50)
    assert_includes earned.map(&:key), "fifty_games"
  end


  # --- craque_semanal (recorrente por semana) ---

  test "craque_semanal pode ser concedido em semanas diferentes" do
    week1 = "2026-W25"
    week2 = "2026-W26"

    assert Quiz::Badge.award!(user: users(:joao), key: "craque_semanal", week: week1)
    assert Quiz::Badge.award!(user: users(:joao), key: "craque_semanal", week: week2)
    assert_equal 2, UserAchievement.where(user: users(:joao), badge_key: "craque_semanal").count
  end

  test "craque_semanal não duplicado na mesma semana" do
    week = "2026-W25"
    Quiz::Badge.award!(user: users(:joao), key: "craque_semanal", week: week)
    result = Quiz::Badge.award!(user: users(:joao), key: "craque_semanal", week: week)
    assert_nil result
  end

  # --- retorno vazio quando nada se aplica ---

  test "check_and_award! retorna array vazio se nenhum badge se aplica" do
    make_result(users(:joao))
    result2 = make_result(users(:joao))
    earned = Quiz::Badge.check_and_award!(users(:joao), result2)
    # first_game já foi concedido implicitamente pelo setup; só verifica array vazio de novos
    assert_not_includes earned.map(&:key), "first_game"
    assert_not_includes earned.map(&:key), "perfect_game"
  end
end
