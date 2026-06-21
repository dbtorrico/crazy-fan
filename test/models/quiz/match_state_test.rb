require "test_helper"

class Quiz::MatchStateTest < ActiveSupport::TestCase
  test "start sem tema sorteia de todas as perguntas" do
    match = Quiz::MatchState.start(nickname: "Torcedor")
    assert_nil match.tema
    assert_equal 5, match.question_ids.size
  end

  test "start com tema filtra perguntas daquele tema" do
    match = Quiz::MatchState.start(nickname: "Torcedor", tema: "Copa do Mundo")
    assert_equal "Copa do Mundo", match.tema
    assert_equal 5, match.question_ids.size
    temas = ::Question.where(id: match.question_ids.select(&:positive?)).pluck(:tema).uniq
    assert_equal [ "Copa do Mundo" ], temas
  end

  test "tema é serializado e restaurado pelo to_h / load" do
    original = Quiz::MatchState.start(nickname: "Torcedor", tema: "História")
    restored = Quiz::MatchState.load(original.to_h)
    assert_equal "História", restored.tema
  end

  test "load de estado legado sem tema não quebra" do
    hash = {
      nickname: "Legado", position: 0, score: 0, correct_count: 0,
      question_ids: [ -1, -2, -3, -4, -5 ], last_choice: nil,
      revealed: false, deadline_at: Time.current.to_f
    }
    match = Quiz::MatchState.load(hash)
    assert_nil match.tema
  end
end
