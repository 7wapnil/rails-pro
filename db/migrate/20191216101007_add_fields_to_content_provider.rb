# frozen_string_literal: true

class AddFieldsToContentProvider < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_content_providers,
               :visible, :boolean, default: false

    add_column :every_matrix_content_providers,
               :as_vendor, :boolean, default: false
  end
end
