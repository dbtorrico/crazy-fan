require "csv"

namespace :content do
  desc "Detecta perguntas sobre 2026 com verbos no futuro; gera CSV com sugestão de presente em tmp/"
  task check_future_tense: :environment do
    # Futuro do indicativo → presente (a Copa 2026 já está acontecendo; ver spec PQ-3).
    replacements = {
      "sediará"    => "sedia",
      "será"       => "é",
      "terá"       => "tem",
      "disputará"  => "disputa",
      "acontecerá" => "acontece",
      "ocorrerá"   => "ocorre"
    }

    pattern = /\b(#{replacements.keys.join("|")})\b/i

    rows = []
    Question.where("enunciado LIKE ?", "%2026%").find_each do |q|
      detected = q.enunciado.scan(pattern).flatten
      next if detected.empty?

      sugestao = q.enunciado.gsub(pattern) { |verbo| replacements[verbo.downcase] || verbo }
      rows << [q.id, q.enunciado, detected.uniq.join(" | "), sugestao]
    end

    path = Rails.root.join("tmp", "future_tense_candidates.csv")
    CSV.open(path, "w") do |csv|
      csv << %w[id enunciado texto_detectado sugestão]
      rows.each { |r| csv << r }
    end

    puts "#{rows.size} pergunta(s) com futuro + 2026 → #{path}"
  end
end
