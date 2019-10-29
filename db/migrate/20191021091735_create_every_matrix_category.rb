# frozen_string_literal: true

class CreateEveryMatrixCategory < ActiveRecord::Migration[5.2]
  def change
    create_table :every_matrix_categories do |t|
      t.string :name, unique: true, index: true
      t.string :label, default: ''
      t.integer :position
      t.string :kind
    end
  end
end
