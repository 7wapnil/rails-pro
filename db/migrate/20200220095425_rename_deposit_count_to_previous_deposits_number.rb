class RenameDepositCountToPreviousDepositsNumber < ActiveRecord::Migration[5.2]
  def change
    rename_column :bonuses, :deposit_count, :previous_deposits_number
  end
end
