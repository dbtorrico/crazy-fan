class CreateUserAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.string :week, null: false, default: ""
      t.datetime :earned_at, null: false

      t.timestamps
    end

    add_index :user_achievements, [:user_id, :badge_key, :week], unique: true
  end
end
