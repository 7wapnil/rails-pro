# frozen_string_literal: true

class ChangeLimitsFieldTypeForPlayItemsDetails < ActiveRecord::Migration[5.2]
  def up
    add_column :every_matrix_table_details,
               :currency_limits, :jsonb, default: {}

    remove_columns :every_matrix_table_details, :min_limit, :max_limit
  end

  def down
    remove_column :every_matrix_table_details, :currency_limits

    add_column :every_matrix_table_details, :max_limit,
               :decimal, precision: 9, scale: 4, default: 0

    add_column :every_matrix_table_details, :min_limit,
               :decimal, precision: 9, scale: 4, default: 0
  end
end
