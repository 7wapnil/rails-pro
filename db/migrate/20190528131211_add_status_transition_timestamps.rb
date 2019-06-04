class AddStatusTransitionTimestamps < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_bonuses, :activated_at, :timestamp
    add_column :customer_bonuses, :deactivated_at, :timestamp
  end
end
