# frozen_string_literal: true

class AddKindToCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_categories, :platform_type, :string, index: true
  end
end
