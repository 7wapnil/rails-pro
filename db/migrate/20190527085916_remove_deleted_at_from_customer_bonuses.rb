class RemoveDeletedAtFromCustomerBonuses < ActiveRecord::Migration[5.2]
  def change
    remove_column :customer_bonuses, :deleted_at
  end
end
