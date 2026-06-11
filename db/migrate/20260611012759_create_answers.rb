class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.string :texto
      t.boolean :correta
      t.string :fonte

      t.timestamps
    end
  end
end
