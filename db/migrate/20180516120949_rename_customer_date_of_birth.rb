class RenameCustomerDateOfBirth < ActiveRecord::Migration[5.2]
  def change
    rename_column :customers, :birth_date, :date_of_birth
  end
end
