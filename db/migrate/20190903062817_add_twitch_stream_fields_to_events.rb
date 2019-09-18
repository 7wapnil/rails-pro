class AddTwitchStreamFieldsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :twitch_start_time, :datetime
    add_column :events, :twitch_end_time, :datetime
    add_column :events, :twitch_url, :string
  end
end
