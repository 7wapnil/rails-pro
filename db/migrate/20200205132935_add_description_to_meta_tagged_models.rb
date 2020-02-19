# frozen_string_literal: true

class AddDescriptionToMetaTaggedModels < ActiveRecord::Migration[5.2]
  def up
    add_column :titles, :meta_description, :text
    add_column :event_scopes, :meta_description, :text
    add_column :every_matrix_categories, :meta_description, :text
    add_column :every_matrix_content_providers, :meta_description, :text
    add_column :every_matrix_vendors, :meta_description, :text
    add_column :every_matrix_play_items, :meta_description, :text

    rename_column :events, :description, :meta_description
    change_column :every_matrix_play_items, :description, :text
  end

  def down
    remove_column :titles, :meta_description
    remove_column :event_scopes, :meta_description
    remove_column :every_matrix_categories, :meta_description
    remove_column :every_matrix_content_providers, :meta_description
    remove_column :every_matrix_vendors, :meta_description
    remove_column :every_matrix_play_items, :meta_description

    rename_column :events, :meta_description, :description
    change_column :every_matrix_play_items, :description, :string
  end
end
