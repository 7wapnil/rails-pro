# frozen_string_literal: true

class AddBalanceEntryToCustomerBonuses < ActiveRecord::Migration[5.2]
  def change
    add_reference :customer_bonuses, :balance_entry,
                  index: true,
                  foreign_key: true
  end
end
