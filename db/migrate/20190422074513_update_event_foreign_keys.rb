class UpdateEventForeignKeys < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :event_competitors, :events
    remove_foreign_key :event_competitors, :competitors
    remove_foreign_key :competitor_players, :competitors
    remove_foreign_key :competitor_players, :players

    add_foreign_key :event_competitors, :events, on_delete: :cascade
    add_foreign_key :event_competitors, :competitors, on_delete: :cascade
    add_foreign_key :competitor_players, :competitors, on_delete: :cascade
    add_foreign_key :competitor_players, :players, on_delete: :cascade
  end
end
