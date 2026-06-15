module Quiz
  # Regra de energia centralizada (config + regeneração por intervalo).
  # PORO puro, sem ActiveRecord: recebe valores, devolve valores.
  # A energia é computada sob demanda a partir de (stored, updated_at) — sem job.
  module Energy
    MAX               = 5
    RECHARGE_INTERVAL = 2.hours   # ← muda aqui para recalibrar a recarga
    GUEST_MAX         = 3

    module_function

    # Energia regenerada virtual no instante `now`, limitada a MAX.
    def current(stored:, updated_at:, now: Time.current)
      settle(stored: stored, updated_at: updated_at, now: now).first
    end

    # Devolve [energia, updated_at] "acertados": aplica a regeneração e avança
    # o relógio preservando o resto (ou `now` quando atinge o teto).
    def settle(stored:, updated_at:, now: Time.current)
      return [ MAX, now ]              if updated_at.nil?   # pré-feature / cheia
      return [ stored, updated_at ]    if stored >= MAX

      regen = ((now - updated_at) / RECHARGE_INTERVAL.to_i).floor
      return [ stored, updated_at ]    if regen <= 0

      new_energy     = [ stored + regen, MAX ].min
      new_updated_at = new_energy >= MAX ? now : updated_at + regen * RECHARGE_INTERVAL
      [ new_energy, new_updated_at ]
    end

    # Instante da próxima recarga, ou nil se já está cheia.
    def next_recharge_at(stored:, updated_at:, now: Time.current)
      energy, ts = settle(stored: stored, updated_at: updated_at, now: now)
      return nil if energy >= MAX

      ts + RECHARGE_INTERVAL
    end
  end
end
