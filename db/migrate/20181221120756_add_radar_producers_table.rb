class AddRadarProducersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :radar_providers do |t|
      t.string :code, index: true
      t.string :state
      t.datetime :last_successful_subscribed_at
      t.datetime :recover_requested_at
      t.integer :recovery_snapshot_id, index: true
      t.integer :recovery_node_id
    end
  end
end
