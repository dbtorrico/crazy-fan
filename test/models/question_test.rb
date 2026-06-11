require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  def valid_question
    q = Question.new(enunciado: "Quem ganhou a Copa de 2002?")
    q.answers.build(texto: "Brasil", correta: true)
    q.answers.build(texto: "Alemanha", correta: false)
    q.answers.build(texto: "Argentina", correta: false)
    q.answers.build(texto: "França", correta: false)
    q
  end

  test "válida com enunciado único e exatamente uma resposta correta" do
    assert valid_question.valid?
  end

  test "inválida sem enunciado" do
    q = valid_question
    q.enunciado = ""
    assert_not q.valid?
    assert_includes q.errors[:enunciado], "can't be blank"
  end

  test "inválida com enunciado duplicado" do
    valid_question.save!
    duplicata = valid_question
    assert_not duplicata.valid?
    assert_includes duplicata.errors[:enunciado], "has already been taken"
  end

  test "inválida sem nenhuma resposta correta" do
    q = Question.new(enunciado: "Pergunta sem correta")
    q.answers.build(texto: "A", correta: false)
    q.answers.build(texto: "B", correta: false)
    q.answers.build(texto: "C", correta: false)
    q.answers.build(texto: "D", correta: false)
    assert_not q.valid?
    assert_includes q.errors[:base], "deve ter exatamente uma resposta correta"
  end

  test "inválida com duas respostas corretas" do
    q = Question.new(enunciado: "Pergunta com duas corretas")
    q.answers.build(texto: "A", correta: true)
    q.answers.build(texto: "B", correta: true)
    q.answers.build(texto: "C", correta: false)
    q.answers.build(texto: "D", correta: false)
    assert_not q.valid?
    assert_includes q.errors[:base], "deve ter exatamente uma resposta correta"
  end
end
