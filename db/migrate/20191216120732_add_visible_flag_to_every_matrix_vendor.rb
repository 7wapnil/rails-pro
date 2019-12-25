# frozen_string_literal: true

class AddVisibleFlagToEveryMatrixVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_vendors, :visible, :boolean, default: false
  end
end
