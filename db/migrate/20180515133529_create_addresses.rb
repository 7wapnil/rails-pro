class CreateAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.references :customer, foreign_key: true
      t.integer :country
      t.string :state
      t.string :city
      t.string :address
      t.string :zip_code

      t.timestamps
    end
  end
end
