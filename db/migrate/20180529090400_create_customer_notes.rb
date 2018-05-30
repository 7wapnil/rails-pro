class CreateCustomerNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :customer_notes do |t|
      t.references :customer, foreign_key: true
      t.references :user, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
