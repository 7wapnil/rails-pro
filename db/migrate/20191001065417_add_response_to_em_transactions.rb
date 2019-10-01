class AddResponseToEmTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :em_transactions, :response, :jsonb
  end
end
