module Quiz
  # Rankings por período (config + montagem das linhas de exibição).
  # PORO no padrão de Quiz::Energy: regra num lugar só, fácil de estender.
  #
  # Para ligar um novo período (mensal, geral) basta adicionar UMA linha em PERIODS.
  # A agregação (GameResult.leaderboard) e a view não mudam.
  module Leaderboard
    # Um período de ranking: chave, rótulo e a janela de tempo (->(now) { Range | nil }).
    # window nil = "todo o período" (ranking geral agregado).
    Period = Struct.new(:key, :label, :window, keyword_init: true)

    # Linha de exibição uniforme — a view não precisa saber qual período é.
    Entry = Struct.new(:rank, :user_id, :nickname, :masked_email, :value, :detail, keyword_init: true)

    # Registro de períodos. A ordem aqui é a ordem do toggle.
    # Inicialmente só o semanal está habilitado; ligar os demais = descomentar/+1 linha.
    PERIODS = [
      Period.new(key: :weekly, label: "Semanal", window: ->(now) { now.beginning_of_week.. })
      # Futuro (1 linha cada):
      # Period.new(key: :monthly,  label: "Mensal", window: ->(now) { now.beginning_of_month.. }),
      # Period.new(key: :all_time, label: "Geral",  window: ->(_now) { nil }),
    ].freeze

    module_function

    # Períodos habilitados (para montar o toggle).
    def periods
      PERIODS
    end

    # Acha o período pela chave; chave ausente/inválida cai no primeiro (default).
    def find_period(key)
      PERIODS.find { |p| p.key.to_s == key.to_s } || PERIODS.first
    end

    # Lista de Entry uniformes para o período pedido.
    def for(period_key, now: Time.current, limit: 50)
      period = find_period(period_key)
      rows   = GameResult.leaderboard(window: period.window.call(now), limit: limit)

      rows.each_with_index.map do |row, i|
        plays = row.plays.to_i
        Entry.new(
          rank:         i + 1,
          user_id:      row.user_id,
          nickname:     row.nickname.presence || "Anônimo",
          masked_email: mask_email(row.email),
          value:        row.total_score.to_i,
          detail:       "#{plays} #{plays == 1 ? 'partida' : 'partidas'}"
        )
      end
    end

    # Email ofuscado para exibição pública: 1ª letra do local + ***@ + domínio.
    # Nunca expõe o local inteiro (mesmo com 1 caractere).
    def mask_email(email)
      return "" if email.blank?

      local, domain = email.split("@", 2)
      return "" if domain.blank?

      "#{local[0]}***@#{domain}"
    end
  end
end
