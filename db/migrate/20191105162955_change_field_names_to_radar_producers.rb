# frozen_string_literal: true

class ChangeFieldNamesToRadarProducers < ActiveRecord::Migration[5.2]
  def change
    rename_column :radar_providers, :recover_requested_at,
                  :recovery_requested_at

    rename_column :radar_providers, :last_successful_subscribed_at,
                  :last_subscribed_at

    rename_column :radar_providers, :last_disconnection_at,
                  :last_disconnected_at
  end
end
