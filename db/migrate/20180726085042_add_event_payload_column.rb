class AddEventPayloadColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :payload, :json
  end
end
