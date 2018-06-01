class CreateBalances < ActiveRecord::Migration[5.2]
  def change
    create_table :balances do |t|
      t.references :wallet, foreign_key: true
      t.integer :type
      t.decimal :amount, precision: 8, scale: 2

      t.timestamps
    end
  end
end
