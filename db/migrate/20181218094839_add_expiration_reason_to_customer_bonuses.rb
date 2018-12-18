class AddExpirationReasonToCustomerBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_bonuses, :expiration_reason, :integer
  end
end
