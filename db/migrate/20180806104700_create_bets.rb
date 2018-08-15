class CreateBets < ActiveRecord::Migration[5.2]
  def change
    create_table :bets do |t|
      t.references :customer, foreign_key: true
      t.references :odd, foreign_key: true
      t.references :currency, foreign_key: true
      t.decimal :amount
      t.decimal :odd_value
      t.integer :status
      t.text :message

      t.timestamps
    end
  end
end
