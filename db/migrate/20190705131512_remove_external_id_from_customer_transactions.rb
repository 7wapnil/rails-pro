# frozen_string_literal: true

class RemoveExternalIdFromCustomerTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_column :customer_transactions, :external_id, :string
  end
end
