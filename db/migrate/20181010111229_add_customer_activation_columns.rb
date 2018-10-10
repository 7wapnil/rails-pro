class AddCustomerActivationColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :activated, :boolean, default: false
    add_column :customers, :activation_token, :string
    add_index :customers, :activation_token, unique: true
  end
end
