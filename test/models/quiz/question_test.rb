require "test_helper"

class Quiz::QuestionTest < ActiveSupport::TestCase
  # --- sample_ids sem filtro ---

  test "sample_ids retorna n ids do banco quando há perguntas suficientes" do
    ids = Quiz::Question.sample_ids(5)
    assert_equal 5, ids.size
    assert ids.all?(&:positive?)
  end

  test "sample_ids cai para FALLBACK quando categoria não tem perguntas suficientes" do
    # "Seleção" não existe nos fixtures → cai para FALLBACK (ids negativos)
    ids = Quiz::Question.sample_ids(5, tema: "Seleção")
    assert_equal 5, ids.size
    assert ids.all?(&:negative?), "esperava ids negativos (FALLBACK), mas recebeu: #{ids.inspect}"
  end

  # --- sample_ids com filtro de tema ---

  test "sample_ids com tema retorna apenas perguntas daquele tema" do
    ids = Quiz::Question.sample_ids(5, tema: "Copa do Mundo")
    assert_equal 5, ids.size
    temas = ::Question.where(id: ids).pluck(:tema).uniq
    assert_equal [ "Copa do Mundo" ], temas
  end

  test "sample_ids com tema História retorna perguntas de História" do
    ids = Quiz::Question.sample_ids(5, tema: "História")
    assert_equal 5, ids.size
    temas = ::Question.where(id: ids).pluck(:tema).uniq
    assert_equal [ "História" ], temas
  end

  test "sample_ids com tema inexistente cai para FALLBACK" do
    ids = Quiz::Question.sample_ids(5, tema: "Inexistente")
    assert_equal 5, ids.size
    assert ids.all?(&:negative?)
  end

  test "sample_ids com tema nil não filtra (comportamento padrão)" do
    ids = Quiz::Question.sample_ids(5, tema: nil)
    assert_equal 5, ids.size
    assert ids.all?(&:positive?)
  end

  # --- category_counts ---

  test "category_counts retorna apenas temas com 5 ou mais perguntas válidas" do
    counts = Quiz::Question.category_counts
    assert counts.key?("Copa do Mundo")
    assert counts.key?("História")
    assert counts["Copa do Mundo"] >= 5
    assert counts["História"] >= 5
  end

  test "category_counts não inclui temas sem perguntas" do
    counts = Quiz::Question.category_counts
    assert_not counts.key?("Seleção")
    assert_not counts.key?("Craques")
  end

  # --- CATEGORIES ---

  test "CATEGORIES tem Qualquer tema com key nil como primeiro elemento" do
    first = Quiz::Question::CATEGORIES.first
    assert_nil first[:key]
    assert_equal "Qualquer tema", first[:label]
  end

  test "CATEGORIES inclui Copa do Mundo e História" do
    keys = Quiz::Question::CATEGORIES.map { |c| c[:key] }
    assert_includes keys, "Copa do Mundo"
    assert_includes keys, "História"
  end
end
