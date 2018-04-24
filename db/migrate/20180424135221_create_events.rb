class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.references :discipline, foreign_key: true
      t.references :event, foreign_key: true
      t.string :name
      t.string :kind
      t.text :description
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
