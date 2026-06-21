class GameResult < ApplicationRecord
  belongs_to :user

  validates :score,           presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :correct_count,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :questions_count, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Ranking agregado por usuário dentro de uma janela de tempo.
  # `window` é um Range de `played_at` (ex.: inicio_da_semana..) ou nil para "todo o período".
  # Soma os pontos por usuário e devolve, por linha: user_id, nickname, email, total_score, plays.
  # Ordena por total desc, com `user_id` como desempate estável.
  def self.leaderboard(window: nil, limit: 50)
    rel = joins(:user)
    rel = rel.where(played_at: window) if window
    rel.group("users.id, users.nickname, users.email")
       .select("users.id AS user_id, users.nickname AS nickname, users.email AS email, " \
               "SUM(score) AS total_score, COUNT(*) AS plays")
       .order(Arel.sql("SUM(score) DESC, users.id ASC"))
       .limit(limit)
  end
end
