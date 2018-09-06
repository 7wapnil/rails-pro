class AddRemoteUpdatedAtToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :remote_updated_at, :datetime
  end
end
