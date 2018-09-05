class AddBetResultColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :result, :boolean, default: false
    add_column :bets, :void_factor, :decimal, precision: 2, scale: 1
  end
end
