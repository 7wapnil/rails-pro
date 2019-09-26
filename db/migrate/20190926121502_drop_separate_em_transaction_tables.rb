class DropSeparateEmTransactionTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :em_wagers
    drop_table :em_results
    drop_table :em_rollback
  end
end
