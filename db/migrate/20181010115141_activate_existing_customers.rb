class ActivateExistingCustomers < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      UPDATE customers SET activated = TRUE
    SQL
  end
end
