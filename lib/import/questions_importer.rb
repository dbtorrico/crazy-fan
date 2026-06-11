require "roo"

class QuestionsImporter
  CORRECT_INDEX_RANGE = (1..4).freeze

  def initialize(filepath)
    @filepath = filepath
  end

  def import
    spreadsheet = Roo::Spreadsheet.open(@filepath)
    sheet = spreadsheet.sheet(0)
    imported = 0
    skipped  = 0

    sheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
      enunciado   = cell_value(row, 0)
      tema        = cell_value(row, 1)
      dificuldade = cell_value(row, 2)
      alternativas = (3..6).map { |i| cell_value(row, i) }
      correct_idx  = cell_value(row, 7).to_i
      fonte        = cell_value(row, 8)

      unless valid_row?(enunciado, alternativas, correct_idx)
        Rails.logger.warn("[QuestionsImporter] Linha inválida pulada: #{enunciado.inspect}")
        skipped += 1
        next
      end

      import_row!(enunciado, tema, dificuldade, alternativas, correct_idx, fonte)
      imported += 1
    end

    { imported: imported, skipped: skipped }
  end

  private

  def cell_value(row, index)
    row[index]&.value.to_s.strip.presence
  end

  def valid_row?(enunciado, alternativas, correct_idx)
    enunciado.present? &&
      alternativas.all?(&:present?) &&
      CORRECT_INDEX_RANGE.cover?(correct_idx)
  end

  def import_row!(enunciado, tema, dificuldade, alternativas, correct_idx, fonte)
    ActiveRecord::Base.transaction do
      question = Question.find_or_initialize_by(enunciado: enunciado)
      question.assign_attributes(tema: tema, dificuldade: dificuldade)
      question.save!

      question.answers.delete_all

      alternativas.each_with_index do |texto, i|
        question.answers.create!(
          texto: texto,
          correta: (i + 1) == correct_idx,
          fonte: fonte
        )
      end
    end
  end
end
