# frozen_string_literal: true

class ChangeNameToContextForCategory < ActiveRecord::Migration[5.2]
  def change
    rename_column :every_matrix_categories, :name, :context
  end
end
