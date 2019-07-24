class AddImportFieldsToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :external_id, :bigint
    add_column :customers, :sign_up_ip, :inet

    add_index :customers, :external_id, unique: true
  end
end
