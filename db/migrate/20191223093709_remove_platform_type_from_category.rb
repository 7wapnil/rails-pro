# frozen_string_literal: true

class RemovePlatformTypeFromCategory < ActiveRecord::Migration[5.2]
  def up
    remove_columns :every_matrix_categories, :platform_type
  end

  def down
    add_column :every_matrix_categories, :platform_type, :string
  end
end
