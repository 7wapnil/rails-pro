class AddCryptoAddressToWallet < ActiveRecord::Migration[5.2]
  def change
    create_table :crypto_addresses do |t|
      t.text :address, default: ''
      t.references :wallet, foreign_key: true

      t.timestamps
    end
  end
end
