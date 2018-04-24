class CreateMarkets < ActiveRecord::Migration[5.2]
  def change
    create_table :markets do |t|
      t.references :event, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
