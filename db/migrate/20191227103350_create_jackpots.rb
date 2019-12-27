# frozen_string_literal: true

class CreateJackpots < ActiveRecord::Migration[5.2]
  def change
    create_table :every_matrix_jackpots do |t|
      t.integer :base_currency_amount, default: 0
      t.string :external_id, null: false, index: true, uniq: true

      t.timestamps
    end
  end
end
