class CreateBalanceEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :balance_entries do |t|
      t.references :balance, foreign_key: true
      t.references :entry, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2

      t.timestamps
    end
  end
end
