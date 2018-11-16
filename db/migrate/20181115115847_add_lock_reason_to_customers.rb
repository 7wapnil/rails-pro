class AddLockReasonToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :lock_reason, :integer
  end
end
