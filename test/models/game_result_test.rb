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
end
