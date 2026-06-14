require "test_helper"
require Rails.root.join("lib/import/questions_importer")

class Import::QuestionsImporterTest < ActiveSupport::TestCase
  FIXTURE_PATH = Rails.root.join("test/fixtures/files/questions_sample.xlsx").to_s

  test "importa perguntas validas e cria questions com answers" do
    result = Import::QuestionsImporter.new(FIXTURE_PATH).import
    assert_equal 2, result[:imported]
    assert_equal 1, result[:skipped]

    q = Question.find_by(enunciado: "Quem ganhou a Copa de 2002?")
    assert_not_nil q
    assert_equal 4, q.answers.count
    assert_equal 1, q.answers.where(correta: true).count
    assert q.answers.find_by(correta: true).texto.include?("Brasil")
  end

  test "linhas invalidas sao puladas sem quebrar a importacao" do
    result = Import::QuestionsImporter.new(FIXTURE_PATH).import
    assert_equal 1, result[:skipped]
    assert_nil Question.find_by(enunciado: "Pergunta invalida sem correta")
  end

  test "rodar o importer duas vezes nao duplica perguntas" do
    Import::QuestionsImporter.new(FIXTURE_PATH).import
    count_after_first = Question.count

    Import::QuestionsImporter.new(FIXTURE_PATH).import
    assert_equal count_after_first, Question.count
  end
end
