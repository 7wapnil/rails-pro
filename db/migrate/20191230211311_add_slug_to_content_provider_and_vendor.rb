# frozen_string_literal: true

class AddSlugToContentProviderAndVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_vendors,
               :slug, :string, index: true, default: ''
    add_column :every_matrix_content_providers,
               :slug, :string, index: true, default: ''
  end
end
