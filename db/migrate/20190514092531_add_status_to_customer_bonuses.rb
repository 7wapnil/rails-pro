class AddStatusToCustomerBonuses < ActiveRecord::Migration[5.2]
  CustomerBonus.delete_all

  add_column :customer_bonuses, :status, :string,
             null: false, default: CustomerBonus::INITIAL
end
