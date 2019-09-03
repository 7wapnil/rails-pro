class AddProducerToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_reference :markets, :producer,
                  foreign_key: { to_table: :radar_providers }
  end
end
