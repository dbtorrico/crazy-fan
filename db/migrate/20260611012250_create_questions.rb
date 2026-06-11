class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.string :tema
      t.string :dificuldade
      t.text :enunciado, null: false

      t.timestamps
      t.index :enunciado, unique: true
    end
  end
end
