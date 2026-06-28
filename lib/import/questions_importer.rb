require "roo"

module Import
  # Importa perguntas de uma planilha .xlsx para o banco.
  #
  # O importer é *header-aware*: localiza cada coluna pelo NOME do cabeçalho
  # (normalizado), e não pela posição. Isso reconcilia dois formatos que antes
  # eram incompatíveis:
  #
  #   - Banco-mestre da skill `torcedor-maluco`:
  #     ID | Tema | Dificuldade | Pergunta | Alternativa A..D | Resposta Correta (letra A-D) | Fonte
  #   - Formato legado/fixture:
  #     enunciado | tema | dificuldade | alt1..4 | correta (número 1-4) | fonte
  #
  # A coluna ID, quando presente, é ignorada. A resposta correta é aceita tanto
  # como letra (A-D) quanto como índice (1-4). Os temas do banco-mestre são
  # normalizados para as chaves canônicas que o app usa em
  # Quiz::Question::CATEGORIES (ex.: "Copa 2026" => "Copa do Mundo").
  class QuestionsImporter
    CORRECT_INDEX_RANGE = (1..4).freeze

    # Sinônimos de cabeçalho (já normalizados) → campo lógico.
    HEADER_ALIASES = {
      enunciado:   [ "enunciado", "pergunta" ],
      tema:        [ "tema" ],
      dificuldade: [ "dificuldade" ],
      alt1:        [ "alt1", "alternativa a" ],
      alt2:        [ "alt2", "alternativa b" ],
      alt3:        [ "alt3", "alternativa c" ],
      alt4:        [ "alt4", "alternativa d" ],
      correta:     [ "correta", "resposta correta" ],
      fonte:       [ "fonte" ]
    }.freeze

    # Temas do banco-mestre da skill → chaves canônicas do app
    # (Quiz::Question::CATEGORIES). Temas já canônicos passam direto;
    # temas desconhecidos são preservados como vieram.
    TEMA_CANONICO = {
      "copa 2026"              => "Copa do Mundo",
      "copa do mundo"          => "Copa do Mundo",
      "historia das copas"     => "História",
      "historia"               => "História",
      "selecao brasileira"     => "Seleção",
      "selecao"                => "Seleção",
      "craques e curiosidades" => "Craques",
      "craques"                => "Craques"
    }.freeze

    LETTER_TO_INDEX = { "a" => 1, "b" => 2, "c" => 3, "d" => 4 }.freeze

    def initialize(filepath)
      @filepath = filepath
    end

    def import
      sheet    = Roo::Spreadsheet.open(@filepath).sheet(0)
      columns  = column_map(sheet.row(1))
      imported = 0
      skipped  = 0

      sheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
        attrs = extract(row, columns)

        unless valid_row?(attrs)
          Rails.logger.warn("[QuestionsImporter] Linha inválida pulada: #{attrs[:enunciado].inspect}")
          skipped += 1
          next
        end

        import_row!(attrs)
        imported += 1
      end

      { imported: imported, skipped: skipped }
    end

    private

    # Mapeia cada campo lógico para o índice de coluna a partir do cabeçalho.
    def column_map(header_values)
      headers = header_values.each_with_index.to_h { |value, i| [ normalize(value), i ] }
      HEADER_ALIASES.transform_values do |aliases|
        aliases.filter_map { |name| headers[name] }.first
      end
    end

    def extract(row, columns)
      {
        enunciado:    cell_at(row, columns[:enunciado]),
        tema:         canonical_tema(cell_at(row, columns[:tema])),
        dificuldade:  cell_at(row, columns[:dificuldade]),
        alternativas: [ :alt1, :alt2, :alt3, :alt4 ].map { |k| cell_at(row, columns[k]) },
        correct_idx:  parse_correct(cell_at(row, columns[:correta])),
        fonte:        cell_at(row, columns[:fonte])
      }
    end

    def cell_at(row, index)
      return nil if index.nil?
      row[index]&.value.to_s.strip.presence
    end

    def normalize(value)
      value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
    end

    def canonical_tema(tema)
      return tema if tema.nil?
      TEMA_CANONICO.fetch(normalize(tema), tema)
    end

    # Aceita letra (A-D) ou índice (1-4). Retorna 1..4 ou nil.
    def parse_correct(raw)
      return nil if raw.nil?
      key = raw.downcase
      return LETTER_TO_INDEX[key] if LETTER_TO_INDEX.key?(key)
      idx = Integer(raw, exception: false)
      idx if idx && CORRECT_INDEX_RANGE.cover?(idx)
    end

    def valid_row?(attrs)
      attrs[:enunciado].present? &&
        attrs[:alternativas].all?(&:present?) &&
        !attrs[:correct_idx].nil?
    end

    def import_row!(attrs)
      ActiveRecord::Base.transaction do
        question = Question.find_or_initialize_by(enunciado: attrs[:enunciado])
        question.assign_attributes(tema: attrs[:tema], dificuldade: attrs[:dificuldade])
        question.save!

        question.answers.delete_all

        attrs[:alternativas].each_with_index do |texto, i|
          question.answers.create!(
            texto: texto,
            correta: (i + 1) == attrs[:correct_idx],
            fonte: attrs[:fonte]
          )
        end
      end
    end
  end
end
