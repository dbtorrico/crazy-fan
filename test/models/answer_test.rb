require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  def setup
    @question = Question.create!(enunciado: "Qual país ganhou a Copa de 2002?")
  end

  test "válida com texto e vínculo à pergunta" do
    answer = Answer.new(texto: "Brasil", correta: true, question: @question)
    assert answer.valid?
  end

  test "inválida sem texto" do
    answer = Answer.new(texto: "", correta: false, question: @question)
    assert_not answer.valid?
    assert_includes answer.errors[:texto], "can't be blank"
  end

  test "pertence à pergunta correta" do
    answer = Answer.create!(texto: "Brasil", correta: true, question: @question)
    assert_equal @question, answer.question
  end
end
