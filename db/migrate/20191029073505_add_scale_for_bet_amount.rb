class AddScaleForBetAmount < ActiveRecord::Migration[5.2]
  def up
    change_column :bets, :amount, :decimal, precision: 14, scale: 2
  end

  def down
    change_column :bets, :amount, :decimal
  end
end
