class GameResult < ApplicationRecord
  belongs_to :user

  validates :score,           presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :correct_count,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :questions_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
