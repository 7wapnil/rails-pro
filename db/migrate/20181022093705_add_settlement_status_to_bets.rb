class AddSettlementStatusToBets < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :settlement_status, :integer
    remove_column :bets, :result, :boolean
  end
end
