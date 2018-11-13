class AddLockedFieldsToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :locked, :boolean, default: false
    add_column :customers, :locked_until, :datetime
  end
end
