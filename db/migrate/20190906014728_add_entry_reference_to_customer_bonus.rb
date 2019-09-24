class AddEntryReferenceToCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    add_reference :customer_bonuses, :entry, foreign_key: true
  end
end
