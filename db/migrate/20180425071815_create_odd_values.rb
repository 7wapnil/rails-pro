class CreateOddValues < ActiveRecord::Migration[5.2]
  def up
    create_table :odd_values do |t|
      t.references :odd, foreign_key: true
      t.decimal :value

      t.timestamps
    end
  end

  def down
    drop_table :odd_values
  end
end
