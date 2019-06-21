class AddPrimaryKeyToEventCompetitor < ActiveRecord::Migration[5.2]
  def change
    add_column :event_competitors, :id, :primary_key
  end
end
