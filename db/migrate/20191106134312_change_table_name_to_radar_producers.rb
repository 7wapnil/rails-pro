# frozen_string_literal: true

class ChangeTableNameToRadarProducers < ActiveRecord::Migration[5.2]
  def change
    rename_table :radar_providers, :radar_producers
  end
end
