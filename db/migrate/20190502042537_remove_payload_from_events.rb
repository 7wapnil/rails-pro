class RemovePayloadFromEvents < ActiveRecord::Migration[5.2]
  def change
    remove_column :events, :payload, :json
  end
end
