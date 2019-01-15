class RenameCustomerBonusSourceToEntry < ActiveRecord::Migration[5.2]
  def change
    rename_column :customer_bonuses, :source_id, :entry_id
  end
end
