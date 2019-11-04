class AddProducerIdToEvents < ActiveRecord::Migration[5.2]
  def up
    add_reference :events,
                  :producer,
                  index: true,
                  foreign_key: { to_table: :radar_providers }
  end

  def down
    remove_reference :events,
                     :producer,
                     index: true,
                     foreign_key: true
  end
end
