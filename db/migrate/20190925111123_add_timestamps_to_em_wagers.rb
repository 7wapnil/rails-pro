class AddTimestampsToEmWagers < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :em_wagers, null: true
  end
end
