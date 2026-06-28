require "test_helper"
require Rails.root.join("lib/import/questions_importer")

class Import::QuestionsImporterTest < ActiveSupport::TestCase
  FIXTURE_PATH        = Rails.root.join("test/fixtures/files/questions_sample.xlsx").to_s
  MASTER_FORMAT_PATH  = Rails.root.join("test/fixtures/files/questions_master_format.xlsx").to_s

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

  # --- Formato do banco-mestre da skill (coluna ID, resposta por letra, temas rotulados) ---

  test "importa o formato do banco-mestre: ignora ID e lê resposta por letra" do
    result = Import::QuestionsImporter.new(MASTER_FORMAT_PATH).import
    assert_equal 2, result[:imported]
    assert_equal 1, result[:skipped]

    q = Question.find_by(enunciado: "Quantas Copas o Brasil venceu?")
    assert_not_nil q, "enunciado deve vir da coluna 'Pergunta', não da coluna 'ID'"
    assert_equal 4, q.answers.count
    correta = q.answers.find_by(correta: true)
    assert_equal "5", correta.texto, "letra C deve mapear para a 3ª alternativa"
  end

  test "normaliza temas do banco-mestre para as chaves canônicas do app" do
    Import::QuestionsImporter.new(MASTER_FORMAT_PATH).import

    copa = Question.find_by(enunciado: "Quais países sediam a Copa de 2026?")
    assert_equal "Copa do Mundo", copa.tema

    selecao = Question.find_by(enunciado: "Quantas Copas o Brasil venceu?")
    assert_equal "Seleção", selecao.tema
  end

  test "linha sem resposta marcada é pulada no formato do banco-mestre" do
    Import::QuestionsImporter.new(MASTER_FORMAT_PATH).import
    assert_nil Question.find_by(enunciado: "Linha sem resposta marcada para testar skip?")
  end
end
