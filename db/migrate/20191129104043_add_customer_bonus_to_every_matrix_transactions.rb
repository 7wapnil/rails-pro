class AddCustomerBonusToEveryMatrixTransactions < ActiveRecord::Migration[5.2]
  def change
    add_reference :every_matrix_transactions, :customer_bonus, foreign_key: true
  end
end
