class AddIndexOnTransactionIdToEmTransactions < ActiveRecord::Migration[5.2]
  def change
    add_index :em_transactions, :transaction_id
  end
end
