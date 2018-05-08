class CreateScopedEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :scoped_events do |t|
      t.references :event_scope, foreign_key: true
      t.references :event, foreign_key: true

      t.timestamps
    end
  end
end
