class AddQualifierToEventCompetitor < ActiveRecord::Migration[5.2]
  def change
    add_column :event_competitors, :qualifier, :string
  end
end
