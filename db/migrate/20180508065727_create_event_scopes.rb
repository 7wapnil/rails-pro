class CreateEventScopes < ActiveRecord::Migration[5.2]
  def change
    create_table :event_scopes do |t|
      t.references :discipline, foreign_key: true
      t.references :event_scope, foreign_key: true
      t.string :name
      t.integer :kind, default: 0

      t.timestamps
    end
  end
end
