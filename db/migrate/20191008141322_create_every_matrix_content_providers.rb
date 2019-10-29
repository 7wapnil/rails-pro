# frozen_string_literal: true

class CreateEveryMatrixContentProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :every_matrix_content_providers do |t|
      t.string :name, null: false, index: true
      t.string :logo_url
      t.boolean :enabled, default: false
      t.string :representation_name, null: false, index: true

      t.timestamps
    end
  end
end
