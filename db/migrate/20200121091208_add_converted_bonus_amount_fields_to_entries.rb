class AddConvertedBonusAmountFieldsToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entry_requests, :converted_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries, :converted_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries, :base_currency_converted_bonus_amount,
               :decimal, precision: 14, scale: 2, default: 0
    add_column :entries, :converted_bonus_amount_after,
               :decimal, precision: 14, scale: 2, default: 0
  end
end
