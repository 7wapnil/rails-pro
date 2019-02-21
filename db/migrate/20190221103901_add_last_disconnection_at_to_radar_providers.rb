class AddLastDisconnectionAtToRadarProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :radar_providers, :last_disconnection_at, :timestamp
  end
end
