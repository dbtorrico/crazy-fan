class CreateGameResults < ActiveRecord::Migration[7.2]
  def change
    create_table :game_results do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :score,           null: false
      t.integer :correct_count,   null: false
      t.integer :questions_count, null: false, default: 5
      t.datetime :played_at,      null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :game_results, [ :user_id, :played_at ]
  end
end
