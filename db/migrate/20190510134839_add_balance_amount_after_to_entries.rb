# frozen_string_literal: true

class AddBalanceAmountAfterToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :balance_amount_after, :decimal,
               precision: 8, scale: 2
  end
end
