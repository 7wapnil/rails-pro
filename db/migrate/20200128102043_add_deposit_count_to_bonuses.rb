class AddDepositCountToBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :deposit_count, :integer
  end
end
