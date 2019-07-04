class AddTosAcceptanceToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :agreed_with_privacy, :boolean
  end
end
