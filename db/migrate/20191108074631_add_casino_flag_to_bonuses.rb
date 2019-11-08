class AddCasinoFlagToBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column(:bonuses, :casino, :boolean,
               null: false, default: false)
    add_column(:customer_bonuses, :casino, :boolean,
               null: false, default: false)
  end
end
