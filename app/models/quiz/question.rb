module Quiz
  # Adapter sobre o Question ActiveRecord existente.
  # Expõe a mesma interface que o PORO do handoff (.find, .sample_ids,
  # #text, #options, #correct_index) sem tocar no modelo AR nem migrar nada.
  # Quando o banco está vazio, cai para o FALLBACK in-memory.
  class Question
    attr_reader :id, :text, :options, :correct_index

    def initialize(id:, text:, options:, correct_index:)
      @id            = id
      @text          = text
      @options       = options
      @correct_index = correct_index
    end

    def self.from_record(record)
      sorted = record.answers.order(:id).to_a
      new(
        id:            record.id,
        text:          record.enunciado,
        options:       sorted.map(&:texto),
        correct_index: sorted.index(&:correta) || 0
      )
    end

    def self.find(id)
      return FALLBACK_BY_ID.fetch(id) if id.negative?
      rec = ::Question.includes(:answers).find_by(id: id)
      return from_record(rec) if rec&.answers.any?
      FALLBACK_BY_ID.fetch(id)
    end

    def self.sample_ids(n)
      ids = ::Question
              .joins(:answers)
              .group("questions.id")
              .having("COUNT(answers.id) >= 4")
              .order("RANDOM()")
              .limit(n)
              .pluck(:id)
      return ids if ids.size >= n
      FALLBACK.sample(n).map(&:id)
    end

    FALLBACK = [
      new(id: -1,
          text: "Em quantos países será disputada a Copa do Mundo de 2026?",
          options: [ "Apenas 1", "2 países", "3 países", "4 países" ],
          correct_index: 2),
      new(id: -2,
          text: "Quantos jogadores cada time começa em campo numa partida?",
          options: [ "9", "10", "11", "12" ],
          correct_index: 2),
      new(id: -3,
          text: "Quanto tempo dura cada tempo de uma partida oficial?",
          options: [ "40 minutos", "45 minutos", "50 minutos", "60 minutos" ],
          correct_index: 1),
      new(id: -4,
          text: "Qual cartão o árbitro mostra para expulsar um jogador?",
          options: [ "Amarelo", "Azul", "Vermelho", "Verde" ],
          correct_index: 2),
      new(id: -5,
          text: "Como é chamado o gol que o jogador marca contra a própria equipe?",
          options: [ "Gol olímpico", "Gol contra", "Gol de placa", "Frango" ],
          correct_index: 1),
      new(id: -6,
          text: "Qual seleção tem mais títulos mundiais?",
          options: [ "Alemanha", "Argentina", "Brasil", "Itália" ],
          correct_index: 2),
      new(id: -7,
          text: "Quantos times participam da fase de grupos da Copa 2026?",
          options: [ "24 times", "32 times", "36 times", "48 times" ],
          correct_index: 3)
    ].freeze
    FALLBACK_BY_ID = FALLBACK.index_by(&:id).freeze
  end
end
