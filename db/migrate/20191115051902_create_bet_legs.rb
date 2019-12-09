class CreateBetLegs < ActiveRecord::Migration[5.2]
  def change
    create_table :bet_legs do |t|
      t.references :bet, foreign_key: true
      t.references :odd, foreign_key: true
      t.decimal :odd_value
      t.text :notification_message
      t.string :notification_code

      t.timestamps
    end
  end
end
