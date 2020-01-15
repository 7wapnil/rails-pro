# frozen_string_literal: true

class AddPositionToProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_vendors, :position, :integer
    add_column :every_matrix_content_providers, :position, :integer
  end
end
