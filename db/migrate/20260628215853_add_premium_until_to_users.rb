class AddPremiumUntilToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :premium_until, :datetime
  end
end
