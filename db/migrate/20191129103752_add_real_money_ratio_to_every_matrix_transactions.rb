class AddRealMoneyRatioToEveryMatrixTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_transactions, :real_money_ratio,
               :decimal, null: false, default: 1
  end
end
