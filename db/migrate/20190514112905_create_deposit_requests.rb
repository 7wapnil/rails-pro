# frozen_string_literal: true

class CreateDepositRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :deposit_requests do |t|
      t.references :customer_bonus, foreign_key: true

      t.timestamps
    end
  end
end
