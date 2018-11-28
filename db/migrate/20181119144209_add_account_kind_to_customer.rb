class AddAccountKindToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :account_kind, :integer, default: 0
  end
end
