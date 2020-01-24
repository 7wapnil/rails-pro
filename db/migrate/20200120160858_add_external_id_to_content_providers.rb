# frozen_string_literal: true

class AddExternalIdToContentProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_content_providers,
               :external_id, :string, index: true
  end
end
