class DropOddValues < ActiveRecord::Migration[5.2]
  def up
    drop_table :odd_values
  end

  def down
    create_table :odd_values do |t|
      t.references :odd, foreign_key: true
      t.decimal :value
      t.timestamps
    end
  end
end