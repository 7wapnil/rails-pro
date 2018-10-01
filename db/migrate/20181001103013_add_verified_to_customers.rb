class AddVerifiedToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :verified, :boolean, default: false
  end
end
