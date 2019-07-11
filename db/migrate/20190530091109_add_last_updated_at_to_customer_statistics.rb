# frozen_string_literal: true

class AddLastUpdatedAtToCustomerStatistics < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_statistics, :last_updated_at, :timestamp
  end
end
