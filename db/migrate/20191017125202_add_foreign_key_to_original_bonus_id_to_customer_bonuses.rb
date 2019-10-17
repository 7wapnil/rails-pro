class AddForeignKeyToOriginalBonusIdToCustomerBonuses < ActiveRecord::Migration[5.2] # rubocop:disable Metrics/LineLength
  def up
    change_column :customer_bonuses, :original_bonus_id, :bigint
    add_foreign_key :customer_bonuses, :bonuses, column: :original_bonus_id
  end

  def down
    remove_foreign_key :customer_bonuses, column: :original_bonus_id
    change_column :customer_bonuses, :original_bonus_id, :integer
  end
end
