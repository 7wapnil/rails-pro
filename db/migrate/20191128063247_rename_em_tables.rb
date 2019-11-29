class RenameEmTables < ActiveRecord::Migration[5.2]
  def change
    rename_table :em_transactions, :every_matrix_transactions
    rename_table :em_wallet_sessions, :every_matrix_wallet_sessions
  end
end
