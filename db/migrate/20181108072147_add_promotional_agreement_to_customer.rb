class AddPromotionalAgreementToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :agreed_with_promotional, :boolean, default: false
  end
end
