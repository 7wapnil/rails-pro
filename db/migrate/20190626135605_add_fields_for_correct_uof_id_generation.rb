# frozen_string_literal: true

class AddFieldsForCorrectUofIdGeneration < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :market_id, :string, defalut: ''
    add_column :markets, :market_specifier, :string, defalut: ''
    add_column :odds, :outcome_id, :string, default: ''
  end
end
