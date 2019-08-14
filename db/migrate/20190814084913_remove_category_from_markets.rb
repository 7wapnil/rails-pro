# frozen_string_literal: true

class RemoveCategoryFromMarkets < ActiveRecord::Migration[5.2]
  def change
    remove_column :markets, :category, :string
  end
end
