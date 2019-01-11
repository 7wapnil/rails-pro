class AddDepositEntryIdToCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_bonuses, :source_id, :integer
  end
end
