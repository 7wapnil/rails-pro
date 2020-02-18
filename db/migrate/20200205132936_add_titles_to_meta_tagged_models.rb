# frozen_string_literal: true

class AddTitlesToMetaTaggedModels < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :meta_title, :string
    add_column :event_scopes, :meta_title, :string
    add_column :every_matrix_categories, :meta_title, :string
    add_column :every_matrix_content_providers, :meta_title, :string
    add_column :every_matrix_vendors, :meta_title, :string
    add_column :events, :meta_title, :string
    add_column :every_matrix_play_items, :meta_title, :string
  end
end
