class RemoveEntryIdFromCustomerBonuses < ActiveRecord::Migration[5.2]
  def change
    remove_column :customer_bonuses, :entry_id, :integer
  end
end
