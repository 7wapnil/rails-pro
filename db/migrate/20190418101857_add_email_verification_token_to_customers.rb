class AddEmailVerificationTokenToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :email_verification_token, :string
    add_index  :customers, :email_verification_token, unique: true
  end
end
