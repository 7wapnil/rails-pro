class AddProducerIdToEvents < ActiveRecord::Migration[5.2]
  def up
    add_reference :events,
                  :producer,
                  index: true,
                  foreign_key: { to_table: Radar::Producer.table_name }
    migrate_data
  end

  def down
    remove_reference :events,
                     :producer,
                     index: true,
                     foreign_key: true
  end

  private

  def migrate_data
    Rake::Task['migrations:event_producers:migrate'].invoke
  end
end
