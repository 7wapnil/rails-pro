# frozen_string_literal: true

class AddExternalStatusToCasinoEntities < ActiveRecord::Migration[5.2]
  def up
    add_column :every_matrix_play_items,
               :external_status, :string, index: true
    add_column :every_matrix_vendors,
               :external_status, :string, index: true
    add_column :every_matrix_content_providers,
               :external_status, :string, index: true
  end

  def down
    remove_column :every_matrix_play_items, :external_status
    remove_column :every_matrix_vendors, :external_status
    remove_column :every_matrix_content_providers, :external_status
  end
end
