require Rails.root.join("lib/import/questions_importer")

planilha = Rails.root.join("banco-perguntas-torcedor-maluco.xlsx")

if planilha.exist?
  result = QuestionsImporter.new(planilha.to_s).import
  puts "Seed concluído: #{result[:imported]} importadas, #{result[:skipped]} puladas."
else
  puts "Planilha não encontrada em #{planilha} — seed pulado."
end
