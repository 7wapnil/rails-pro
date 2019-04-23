class AddVerificationFieldsToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :email_verified, :boolean,
               null: false, default: false
    add_column :customers, :verification_sent, :boolean,
               null: false, default: false
  end
end
