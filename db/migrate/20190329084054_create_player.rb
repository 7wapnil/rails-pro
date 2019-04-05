class CreatePlayer < ActiveRecord::Migration[5.2]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :external_id, null: false
      t.string :full_name
      t.jsonb :details

      t.timestamps
    end
  end
end
