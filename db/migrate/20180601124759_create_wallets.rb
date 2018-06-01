class CreateWallets < ActiveRecord::Migration[5.2]
  def change
    create_table :wallets do |t|
      t.references :customer, foreign_key: true
      t.integer :currency
      t.decimal :amount, precision: 8, scale: 2

      t.timestamps
    end
  end
end
