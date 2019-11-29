class AddRoundIdIndexToEveryMatrixTransactions < ActiveRecord::Migration[5.2]
  def change
    add_index :every_matrix_transactions, :round_id
  end
end
