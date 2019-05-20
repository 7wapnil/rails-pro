class RemoveExpirationReasonFromCustomerBonus < ActiveRecord::Migration[5.2]
  def change
    remove_column :customer_bonuses, :expiration_reason, :string
  end
end
