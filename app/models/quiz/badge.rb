module Quiz
  module Badge
    BadgeInfo = Struct.new(:key, :emoji, :label, keyword_init: true)

    CATALOG = [
      BadgeInfo.new(key: "first_game",     emoji: "🎯", label: "Estreante"),
      BadgeInfo.new(key: "perfect_game",   emoji: "⭐", label: "Perfeito"),
      BadgeInfo.new(key: "ten_games",      emoji: "⚽", label: "Viciado"),
      BadgeInfo.new(key: "fifty_games",    emoji: "🎟️", label: "Fã de Carteirinha"),
      BadgeInfo.new(key: "craque_semanal", emoji: "🏆", label: "Craque da Semana")
    ].freeze

    CATALOG_BY_KEY = CATALOG.index_by(&:key).freeze

    module_function

    def find(key)
      CATALOG_BY_KEY[key.to_s]
    end

    # Tenta conceder um badge. Retorna o registro criado ou nil se já existia.
    def award!(user:, key:, week: "")
      UserAchievement.create!(
        user:      user,
        badge_key: key,
        week:      week,
        earned_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      nil
    end

    # Avalia todos os badges para o usuário após salvar um game_result.
    # Retorna array de BadgeInfo recém-conquistados (pode ser vazio).
    # weekly_leader_id: pré-computado pelo controller para evitar query duplicada.
    def check_and_award!(user, game_result, weekly_leader_id: nil)
      total_games = user.game_results.count
      newly_earned = []

      # Condições exatas (== N) são intencionais: o badge é concedido apenas
      # no jogo que atinge o marco, não retroativamente.
      candidates = [
        [ "first_game",     total_games == 1 ],
        [ "perfect_game",   game_result.correct_count == game_result.questions_count ],
        [ "ten_games",      total_games == 10 ],
        [ "fifty_games",    total_games == 50 ]
      ]

      candidates.each do |key, condition|
        next unless condition
        rec = award!(user: user, key: key)
        newly_earned << CATALOG_BY_KEY[key] if rec
      end

      # craque_semanal: recorrente por semana ISO
      week = Time.current.strftime("%G-W%V")
      if weekly_leader_id == user.id
        rec = award!(user: user, key: "craque_semanal", week: week)
        newly_earned << CATALOG_BY_KEY["craque_semanal"] if rec
      end

      newly_earned
    end
  end
end
