class AddProducerIdToEvents < ActiveRecord::Migration[5.2]
  def up
    add_column :events, :producer_id, :integer, index: true
    migrate_data
  end

  def down
    remove_column :events, :producer_id
  end

  private

  def migrate_data
    Rake::Task['migrations:event_producers:migrate'].invoke
  end
end
