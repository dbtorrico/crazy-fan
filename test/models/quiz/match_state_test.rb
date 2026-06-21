require "test_helper"

class Quiz::MatchStateTest < ActiveSupport::TestCase
  test "start sorteia perguntas de todas as categorias" do
    match = Quiz::MatchState.start(nickname: "Torcedor")
    assert_equal 5, match.question_ids.size
  end

  test "to_h / load preserva o estado corretamente" do
    original = Quiz::MatchState.start(nickname: "Torcedor")
    restored = Quiz::MatchState.load(original.to_h)
    assert_equal original.nickname, restored.nickname
    assert_equal original.question_ids, restored.question_ids
  end

  test "load de estado legado com tema não quebra" do
    hash = {
      nickname: "Legado", tema: "História", position: 0, score: 0, correct_count: 0,
      question_ids: [ -1, -2, -3, -4, -5 ], last_choice: nil,
      revealed: false, deadline_at: Time.current.to_f
    }
    match = Quiz::MatchState.load(hash)
    assert_equal 5, match.question_ids.size
  end
end
