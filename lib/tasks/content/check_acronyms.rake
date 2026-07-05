require "csv"

namespace :content do
  desc "Varre enunciados e respostas por siglas sem explicação entre parênteses; gera CSV em tmp/"
  task check_acronyms: :environment do
    # Siglas que devem vir acompanhadas de explicação, ex.: "CBF (Confederação Brasileira de Futebol)".
    # FIFA e VAR ficam de fora por serem amplamente conhecidas (ver spec PQ-2).
    acronyms = %w[CBF UEFA CONMEBOL CONCACAF CAF AFC OFC IFFHS FPF]

    rows = []

    scan = ->(question_id, enunciado, campo, texto) do
      acronyms.each do |sigla|
        # Candidata: sigla isolada (word boundary) sem explicação — nem seguida de "("
        # (forma "CBF (Confederação...)") nem precedida de "(" (forma "Oceania (OFC)").
        next unless texto&.match?(/(?<!\()\b#{sigla}\b(?!\s*\()/)
        rows << [ question_id, enunciado, campo, texto, sigla ]
      end
    end

    Question.find_each do |q|
      scan.call(q.id, q.enunciado, "enunciado", q.enunciado)
    end

    Answer.includes(:question).find_each do |a|
      scan.call(a.question_id, a.question.enunciado, "resposta", a.texto)
    end

    path = Rails.root.join("tmp", "acronyms_candidates.csv")
    CSV.open(path, "w") do |csv|
      csv << %w[id enunciado campo texto_detectado sigla]
      rows.each { |r| csv << r }
    end

    puts "#{rows.size} candidato(s) encontrado(s) → #{path}"
  end
end
