class CreateOdds < ActiveRecord::Migration[5.2]
  def change
    create_table :odds do |t|
      t.references :market, foreign_key: true
      t.string :name
      t.decimal :value
      t.boolean :won

      t.timestamps
    end
  end
end
