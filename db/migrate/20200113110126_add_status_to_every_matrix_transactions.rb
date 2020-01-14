class AddStatusToEveryMatrixTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_transactions, :status, :string,
               null: false, default: EveryMatrix::Transaction::DEFAULT_STATUS
    add_index :every_matrix_transactions, :status
  end
end
