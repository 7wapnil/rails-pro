class AddApiFieldsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :display_status, :string
    add_column :events, :home_score, :integer
    add_column :events, :away_score, :integer
    add_column :events, :time_in_seconds, :integer
    add_column :events, :liveodds, :string
  end
end
