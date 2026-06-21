class UserAchievement < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true
  validates :earned_at, presence: true
  validates :badge_key, uniqueness: { scope: [:user_id, :week] }
end
