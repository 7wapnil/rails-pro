class RenameActivatedBonusToCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    rename_table :activated_bonuses, :customer_bonuses
  end
end
