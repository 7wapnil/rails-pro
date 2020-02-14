# frozen_string_literal: true

class AddOpeningPropertiesToTable < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_table_details,
               :always_opened, :boolean, default: false
    add_column :every_matrix_table_details,
               :start_time, :string, default: ''
    add_column :every_matrix_table_details,
               :end_time, :string, default: ''
  end
end
