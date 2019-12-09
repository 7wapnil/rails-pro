class AddStatusFieldsToBetLegs < ActiveRecord::Migration[5.2]
  def change
    add_column :bet_legs, :status, :string
    add_column :bet_legs, :settlement_status, :string
    add_column :bet_legs, :void_factor, :decimal, precision: 2, scale: 1
  end
end
