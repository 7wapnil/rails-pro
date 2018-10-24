class UpdateForeignKeys < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :odds, :markets
    remove_foreign_key :markets, :events
    remove_foreign_key :scoped_events, :events
    remove_foreign_key :bets, :odds

    add_foreign_key :odds, :markets, on_delete: :cascade
    add_foreign_key :markets, :events, on_delete: :cascade
    add_foreign_key :scoped_events, :events, on_delete: :cascade
    add_foreign_key :bets, :odds, on_delete: :cascade
  end
end
