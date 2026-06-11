class Answer < ApplicationRecord
  belongs_to :question

  validates :texto, presence: true
end
