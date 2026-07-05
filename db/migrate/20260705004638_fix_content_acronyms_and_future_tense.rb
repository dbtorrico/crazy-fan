# Correções de conteúdo aprovadas na revisão dos CSVs de PQ-2 e PQ-3
# (tmp/acronyms_candidates.csv e tmp/future_tense_candidates.csv, PR #28).
# Casa por texto exato — não por ID — para aplicar igualmente em dev e produção.
class FixContentAcronymsAndFutureTense < ActiveRecord::Migration[7.2]
  QUESTION_FIXES = {
    # PQ-2 — siglas com explicação entre parênteses
    "Quantas seleções africanas a CAF pode classificar diretamente para a Copa de 2026?" =>
      "Quantas seleções africanas a CAF (Confederação Africana de Futebol) pode classificar diretamente para a Copa de 2026?",
    "Pela Ásia, a AFC ganha quantas vagas diretas em 2026?" =>
      "Pela Ásia, a AFC (Confederação Asiática de Futebol) ganha quantas vagas diretas em 2026?",
    "De qual país é a Seleção Brasileira, organizada pela CBF?" =>
      "De qual país é a Seleção Brasileira, organizada pela CBF (Confederação Brasileira de Futebol)?",

    # PQ-3 — futuro do indicativo → presente (a Copa 2026 já está acontecendo)
    "Em qual estádio será disputada a final da Copa de 2026?" =>
      "Em qual estádio é disputada a final da Copa de 2026?",
    "A Copa de 2026 será a primeira a ser organizada por quantos países ao mesmo tempo?" =>
      "A Copa de 2026 é a primeira a ser organizada por quantos países ao mesmo tempo?",
    "Em qual estádio será disputada a partida de abertura da Copa de 2026?" =>
      "Em qual estádio é disputada a partida de abertura da Copa de 2026?",
    "Quantas partidas no total terá a Copa do Mundo de 2026?" =>
      "Quantas partidas no total tem a Copa do Mundo de 2026?",
    "A Europa terá direito a quantas vagas na Copa de 2026?" =>
      "A Europa tem direito a quantas vagas na Copa de 2026?",
    "A Copa de 2026 será disputada principalmente em qual período do ano?" =>
      "A Copa de 2026 é disputada principalmente em qual período do ano?"
  }.freeze

  ANSWER_FIXES = {
    "CONMEBOL" => "CONMEBOL (Confederação Sul-Americana de Futebol)",
    "CONCACAF" => "CONCACAF (Confederação de Futebol da América do Norte, Central e Caribe)",
    "UEFA"     => "UEFA (União das Associações Europeias de Futebol)",
    "AFC"      => "AFC (Confederação Asiática de Futebol)"
  }.freeze

  def up
    apply(QUESTION_FIXES, ANSWER_FIXES)
  end

  def down
    apply(QUESTION_FIXES.invert, ANSWER_FIXES.invert)
  end

  private

  def apply(question_map, answer_map)
    question_map.each do |from, to|
      execute <<~SQL
        UPDATE questions SET enunciado = #{quote(to)}, updated_at = NOW()
        WHERE enunciado = #{quote(from)}
      SQL
    end

    answer_map.each do |from, to|
      execute <<~SQL
        UPDATE answers SET texto = #{quote(to)}, updated_at = NOW()
        WHERE texto = #{quote(from)}
      SQL
    end
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
