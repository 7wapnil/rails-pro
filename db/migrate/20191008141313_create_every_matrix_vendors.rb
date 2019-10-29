# frozen_string_literal: true

class CreateEveryMatrixVendors < ActiveRecord::Migration[5.2]
  def change
    create_table :every_matrix_vendors do |t|
      t.string :name, null: false
      t.bigint :vendor_id, null: false, index: true
      t.string :logo_url
      t.text :restricted_territories, array: true, default: []
      t.boolean :enabled, default: false
      t.text :languages, array: true, default: []
      t.text :currencies, array: true, default: []
      t.boolean :has_live_casino, default: false

      t.timestamps
    end
  end
end
