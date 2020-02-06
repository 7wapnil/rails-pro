class AddAmountTrackingFieldsToCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_bonuses, :total_confiscated_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :customer_bonuses, :total_converted_amount,
               :decimal, precision: 14, scale: 2, default: 0
  end
end
