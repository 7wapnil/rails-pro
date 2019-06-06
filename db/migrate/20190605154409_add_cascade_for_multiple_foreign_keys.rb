# frozen_string_literal: true

class AddCascadeForMultipleForeignKeys < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :entries, :entry_requests
    remove_foreign_key :balance_entries, :entries
    remove_foreign_key :customer_bonuses, :balance_entries
    remove_foreign_key :deposit_requests, :customer_bonuses

    add_foreign_key :entries, :entry_requests, on_delete: :cascade
    add_foreign_key :balance_entries, :entries, on_delete: :cascade
    add_foreign_key :customer_bonuses, :balance_entries, on_delete: :cascade
    add_foreign_key :deposit_requests, :customer_bonuses, on_delete: :cascade
  end
end
