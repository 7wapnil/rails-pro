class CreateOddValues < ActiveRecord::Migration[5.2]
  def change
    create_table :odd_values do |t|
      t.references :odd, foreign_key: true
      t.decimal :value
      t.boolean :active

      t.timestamps
    end
  end
end
