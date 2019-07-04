# frozen_string_literal: true

class AddUniquenessIndexToWallets < ActiveRecord::Migration[5.2]
  def change
    add_index :wallets, %i[customer_id currency_id], unique: true
  end
end
