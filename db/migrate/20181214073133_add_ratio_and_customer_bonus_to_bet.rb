class AddRatioAndCustomerBonusToBet < ActiveRecord::Migration[5.2]
  def change
    add_reference :bets, :customer_bonus
    add_column :bets, :ratio, :decimal, precision: 8, scale: 2
  end
end
