class AddEnergyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :energy,            :integer,  null: false, default: Quiz::Energy::MAX
    add_column :users, :energy_updated_at, :datetime, null: true
  end
end
