class AddBtagToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :b_tag, :string
  end
end
