class AddLockableToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :failed_attempts, :integer, default: 0, null: false
  end
end
