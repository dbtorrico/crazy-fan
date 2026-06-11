class Question < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :enunciado, presence: true, uniqueness: true
  validate :exactly_one_correct_answer

  private

  def exactly_one_correct_answer
    return if answers.none?

    correct_count = answers.count(&:correta)
    errors.add(:base, "deve ter exatamente uma resposta correta") unless correct_count == 1
  end
end
