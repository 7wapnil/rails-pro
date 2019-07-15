class AddTransactionMessageToCustomerTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_transactions, :transaction_message, :string
  end
end
