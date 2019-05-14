class AddStatusToCustomerBonuses < ActiveRecord::Migration[5.2]
  add_column :customer_bonuses, :status, :string,
             null: false, default: CustomerBonus::PENDING

  CustomerBonus.where.not(entry_id: nil)
               .update(status: CustomerBonus::ACTIVE)

  CustomerBonus.where.not(expiration_reason: nil)
               .update(status: CustomerBonus::EXPIRED)

  CustomerBonus.where(expiration_reason: CustomerBonus::CONVERTED)
               .update(status: CustomerBonus::COMPLETED)

  CustomerBonus.where(expiration_reason: CustomerBonus::MANUAL_CANCEL)
               .update(status: CustomerBonus::CANCELLED)
end
