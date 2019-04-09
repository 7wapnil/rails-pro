class CreateCompetitors < ActiveRecord::Migration[5.2]
  def change
    create_table :competitors do |t|
      t.string :name, null: false
      t.string :external_id, null: false
      t.jsonb :details

      t.timestamps
    end
  end
end
