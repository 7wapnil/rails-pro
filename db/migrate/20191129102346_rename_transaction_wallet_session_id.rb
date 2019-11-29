class RenameTransactionWalletSessionId < ActiveRecord::Migration[5.2]
  def change
    rename_column :every_matrix_transactions,
                  :em_wallet_session_id, :wallet_session_id
  end
end
