class RenameEventsStartEndFields < ActiveRecord::Migration[5.2]
  def change
    rename_column(:events, :started_at, :start_at)
    rename_column(:events, :ended_at, :end_at)
  end
end
