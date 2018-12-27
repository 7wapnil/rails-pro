class AddRolloverInfoToCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_bonuses,
               :rollover_balance,
               :decimal,
               precision: 8,
               scale: 2
    add_column :customer_bonuses,
               :rollover_initial_value,
               :decimal,
               precision: 8,
               scale: 2
  end
end
