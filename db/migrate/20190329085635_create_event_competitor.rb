class CreateEventCompetitor < ActiveRecord::Migration[5.2]
  def change
    create_table :event_competitors, id: false do |t|
      t.references :event, foreign_key: true
      t.references :competitor, foreign_key: true
    end
  end
end
