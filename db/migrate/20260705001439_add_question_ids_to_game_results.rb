class AddQuestionIdsToGameResults < ActiveRecord::Migration[7.2]
  def change
    add_column :game_results, :question_ids, :jsonb, default: []
  end
end
