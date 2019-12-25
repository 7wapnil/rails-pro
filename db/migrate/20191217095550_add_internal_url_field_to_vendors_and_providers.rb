# frozen_string_literal: true

class AddInternalUrlFieldToVendorsAndProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_vendors,
               :internal_image_name, :string, default: ''

    add_column :every_matrix_content_providers,
               :internal_image_name, :string, default: ''
  end
end
