class AddCancelledBonusAmountToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :cancelled_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries, :base_currency_cancelled_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries, :cancelled_bonus_amount_after,
               :decimal, precision: 14, scale: 2, default: 0
  end
end
